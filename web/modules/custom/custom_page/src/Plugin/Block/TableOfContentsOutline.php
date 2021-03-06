<?php

declare(strict_types = 1);

namespace Drupal\custom_page\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\Core\Cache\Cache;
use Drupal\Core\Menu\InaccessibleMenuLink;
use Drupal\Core\Menu\MenuActiveTrailInterface;
use Drupal\Core\Menu\MenuLinkInterface;
use Drupal\Core\Menu\MenuLinkTreeElement;
use Drupal\Core\Menu\MenuLinkTreeInterface;
use Drupal\Core\Menu\MenuTreeParameters;
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;
use Drupal\Core\Routing\RouteMatchInterface;
use Drupal\custom_page\CustomPageOgMenuLinksManagerInterface;
use Drupal\og_menu\OgMenuInstanceInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;
use Drupal\Core\Render\Markup;

/**
 * Provides a block with the outline of a table of content in a custom page.
 *
 * @Block(
 *  id = "toc_outline",
 *  admin_label = @Translation("Table of contents outline"),
 *  context = {
 *    "og" = @ContextDefinition("entity", label = @Translation("Group"))
 *  }
 * )
 */
class TableOfContentsOutline extends BlockBase implements ContainerFactoryPluginInterface {

  /**
   * The og menu manager for custom pages.
   *
   * @var \Drupal\custom_page\CustomPageOgMenuLinksManagerInterface
   */
  protected $ogMenuManager;

  /**
   * The custom page.
   *
   * @var \Drupal\node\NodeInterface
   */
  protected $node;

  /**
   * The menu tree manager service.
   *
   * @var \Drupal\Core\Menu\MenuLinkTreeInterface
   */
  protected $menuLinkTree;

  /**
   * The active trail service.
   *
   * @var \Drupal\Core\Menu\MenuActiveTrailInterface
   */
  protected $activeTrail;

  /**
   * The active link.
   *
   * @var \Drupal\Core\Menu\MenuLinkInterface
   */
  protected $activeLink;

  /**
   * The og menu flattened.
   *
   * @var \Drupal\Core\Menu\MenuLinkInterface[]
   */
  protected $flattenedMenu;

  /**
   * The og menu tree.
   *
   * @var \Drupal\Core\Menu\MenuLinkTreeElement[]
   */
  protected $menuTree;

  /**
   * The og menu instance.
   *
   * @var \Drupal\og_menu\OgMenuInstanceInterface
   */
  protected $ogMenuInstance;

  /**
   * Constructs a new RecommendedContentBlock object.
   *
   * @param array $configuration
   *   A configuration array containing information about the plugin instance.
   * @param string $plugin_id
   *   The plugin_id for the plugin instance.
   * @param string $plugin_definition
   *   The plugin implementation definition.
   * @param \Drupal\custom_page\CustomPageOgMenuLinksManagerInterface $og_menu_manager
   *   The og menu manager for custom pages.
   * @param \Drupal\Core\Routing\RouteMatchInterface $route_match
   *   The route provider.
   * @param \Drupal\Core\Menu\MenuLinkTreeInterface $menu_link_tree
   *   The menu tree manager service.
   * @param \Drupal\Core\Menu\MenuActiveTrailInterface $active_trail
   *   The active trail service.
   */
  public function __construct(array $configuration, $plugin_id, $plugin_definition, CustomPageOgMenuLinksManagerInterface $og_menu_manager, RouteMatchInterface $route_match, MenuLinkTreeInterface $menu_link_tree, MenuActiveTrailInterface $active_trail) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);
    $this->ogMenuManager = $og_menu_manager;
    $this->node = $route_match->getParameter('node');
    $this->menuLinkTree = $menu_link_tree;
    $this->activeTrail = $active_trail;
    $this->flattenedMenu = [];
  }

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container, array $configuration, $plugin_id, $plugin_definition) {
    return new static(
      $configuration,
      $plugin_id,
      $plugin_definition,
      $container->get('custom_page.og_menu_links_manager'),
      $container->get('current_route_match'),
      $container->get('menu.link_tree'),
      $container->get('menu.active_trail')
    );
  }

  /**
   * {@inheritdoc}
   */
  public function build(): array {
    // In case no active link is detected, escape early as there are no relative
    // links to the menu.
    if (empty($this->getActiveLink())) {
      return [];
    }

    $prev = $this->getPrevElement();
    $up = $this->getParentElement($this->getMenuTree(), $this->getActiveLink()->getPluginId());
    $next = $this->getNextElement();

    $links = [];
    if ($prev) {
      $links['prev'] = [
        'url' => $prev->getUrlObject(),
        'title' => Markup::create('<span class="icon icon--previous"></span>' . $prev->getTitle()),
      ];
    }
    if ($up) {
      $links['up'] = [
        'url' => $up->link->getUrlObject(),
        'title' => $this->t('Up'),
      ];
    }
    if ($next) {
      $links['next'] = [
        'url' => $next->getUrlObject(),
        'title' => Markup::create($next->getTitle() . '<span class="icon icon--next"></span>'),
      ];
    }

    $build = [
      '#theme' => 'links',
      '#links' => $links,
    ];

    $og_menu_id = $this->getOgMenuName();
    $system_menu_tags = Cache::buildTags('config:system.menu', [$og_menu_id], '.');
    $og_menu_instance_tags = Cache::buildTags('ogmenu_instance', [$this->getOgMenuInstance()->id()]);
    $build['#cache']['tags'] = Cache::mergeTags($system_menu_tags, $og_menu_instance_tags);

    return $build;
  }

  /**
   * Returns the previous element related to the active link.
   *
   * To get the correct element we will get the previous element from the
   * flattened list which is naturally the next element in the list.
   *
   * @return \Drupal\Core\Menu\MenuLinkInterface|null
   *   The previous menu link element or null if no element is found.
   */
  protected function getPrevElement(): ?MenuLinkInterface {
    $flattened_menu = $this->getFlattenedMenu();
    $active_link_id = $this->getActiveLink()->getPluginId();

    reset($flattened_menu);
    $curr = NULL;
    do {
      $prev = $curr;
      $curr = current($flattened_menu);
      next($flattened_menu);
    } while ($curr && $curr->getPluginId() !== $active_link_id);

    return $prev ? $prev : NULL;
  }

  /**
   * Returns the next element related to the active link.
   *
   * To get the correct element we will use the flattened list in which holds
   * the natural prev/next list.
   *
   * @return \Drupal\Core\Menu\MenuLinkInterface|null
   *   The next menu link.
   */
  protected function getNextElement(): ?MenuLinkInterface {
    $flattened_menu = $this->getFlattenedMenu();
    $active_link_id = $this->getActiveLink()->getPluginId();

    reset($flattened_menu);
    do {
      $curr = current($flattened_menu);
      $next = next($flattened_menu);
    } while ($curr && $curr->getPluginId() !== $active_link_id);

    return $next ? $next : NULL;
  }

  /**
   * Returns the parent element related to the active link.
   *
   * Recursively check the structured menu tree in order to obtain the parent
   * link.
   *
   * @param \Drupal\Core\Menu\MenuLinkTreeElement[] $tree
   *   The menu tree or subtree to check for the parent.
   * @param string $active_link_id
   *   The active link id.
   * @param \Drupal\Core\Menu\MenuLinkTreeElement $parent
   *   The current parent found.
   *
   * @return \Drupal\Core\Menu\MenuLinkTreeElement|null
   *   The menu link tree.
   */
  protected function getParentElement(array $tree, string $active_link_id, MenuLinkTreeElement $parent = NULL): ?MenuLinkTreeElement {
    if (empty($tree)) {
      return NULL;
    }

    foreach ($tree as $menu_element) {
      if ($menu_element->link->getPluginId() === $active_link_id) {
        return $parent;
      }
    }

    foreach ($tree as $menu_link_id => $menu_item) {
      if ($parent = $this->getParentElement($tree[$menu_link_id]->subtree, $active_link_id, $menu_item)) {
        return $parent;
      }
    }

    // If none of the above have found the parent, then the link was not found.
    return $parent;
  }

  /**
   * Loads and returns the og menu instance.
   *
   * @return \Drupal\og_menu\OgMenuInstanceInterface
   *   The og menu instance.
   */
  protected function getOgMenuInstance(): OgMenuInstanceInterface {
    if (empty($this->ogMenuInstance)) {
      $this->ogMenuInstance = $this->ogMenuManager->getOgMenuInstanceByCustomPage($this->node);
    }

    return $this->ogMenuInstance;
  }

  /**
   * Returns the active link.
   *
   * @return \Drupal\Core\Menu\MenuLinkInterface
   *   The active link.
   */
  protected function getActiveLink(): MenuLinkInterface {
    if (empty($this->activeLink)) {
      $og_menu_id = $this->getOgMenuName();
      $this->activeLink = $this->activeTrail->getActiveLink($og_menu_id);
    }

    return $this->activeLink;
  }

  /**
   * Returns the menu tree of the current og menu.
   *
   * @return \Drupal\Core\Menu\MenuLinkTreeElement[]
   *   The og menu tree.
   */
  protected function getMenuTree(): array {
    if (empty($this->menuTree)) {
      $og_menu_id = $this->getOgMenuName();
      $menu_tree_parameters = new MenuTreeParameters();
      $menu_tree_parameters->onlyEnabledLinks();
      $this->menuTree = $this->menuLinkTree->load($og_menu_id, $menu_tree_parameters);
      $manipulators = [
        ['callable' => 'menu.default_tree_manipulators:checkAccess'],
        ['callable' => 'menu.default_tree_manipulators:generateIndexAndSort'],
      ];
      $this->menuTree = $this->menuLinkTree->transform($this->menuTree, $manipulators);
    }

    return $this->menuTree;
  }

  /**
   * Retrieves the og menu in a flattened list.
   *
   * @return \Drupal\Core\Menu\MenuLinkTreeElement[]
   *   The flattened menu.
   */
  protected function getFlattenedMenu(): array {
    if (empty($this->flattenedMenu)) {
      $tree = $this->getMenuTree();
      $this->flatOutlineTree($tree);

      $links_to_be_stripped = [
        'entity.rdf_entity.canonical' => 'Overview',
        'entity.rdf_entity.member_overview' => 'Members',
        'entity.rdf_entity.about_page' => 'About',
      ];

      foreach ($this->flattenedMenu as $menu_link_id => $menu_item) {
        $route_name = $menu_item->getRouteName();
        if (isset($links_to_be_stripped[$route_name]) && $links_to_be_stripped[$route_name] == $menu_item->getTitle()) {
          unset($this->flattenedMenu[$menu_link_id]);
        }
      }
    }

    // Inaccessible links are still returned but as an instance of
    // Drupal\Core\Menu\InaccessibleMenuLink. Strip off these links from here.
    $this->flattenedMenu = array_filter($this->flattenedMenu, function (MenuLinkInterface $menu_link) {
      return !($menu_link instanceof InaccessibleMenuLink);
    });

    return $this->flattenedMenu;
  }

  /**
   * Recursively converts a tree of menu links to a flat array.
   *
   * Inspired from the book module and the DefaultMenuLinkTreeManipulators
   * class.
   *
   * @param array $tree
   *   A tree of menu links in an array.
   *
   * @see \Drupal\book\BookManager::flatBookTree
   * @see \Drupal\Core\Menu\DefaultMenuLinkTreeManipulators::flatten
   */
  protected function flatOutlineTree(array $tree): void {
    /** @var \Drupal\Core\Menu\MenuLinkTreeElement[] $tree */
    foreach ($tree as $menu_link_id => $data) {
      $this->flattenedMenu[$menu_link_id] = $data->link;
      if ($data->subtree) {
        $this->flatOutlineTree($data->subtree);
      }
    }
  }

  /**
   * Returns the og menu name.
   *
   * @return string
   *   The og menu name.
   */
  protected function getOgMenuName(): string {
    $og_menu_instance = $this->getOgMenuInstance();
    return 'ogmenu-' . $og_menu_instance->id();
  }

  /**
   * {@inheritdoc}
   */
  public function getCacheContexts() {
    $contexts = parent::getCacheContexts();
    return Cache::mergeContexts($contexts, ['url.path']);
  }

}
