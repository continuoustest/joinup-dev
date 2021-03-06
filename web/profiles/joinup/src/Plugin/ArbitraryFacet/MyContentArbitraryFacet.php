<?php

namespace Drupal\joinup\Plugin\ArbitraryFacet;

use Drupal\search_api_arbitrary_facet\Plugin\ArbitraryFacetBase;

/**
 * Provides supports for facets generated by arbitrary queries.
 *
 * @ArbitraryFacet(
 *   id = "my_content",
 *   label = @Translation("My content"),
 * )
 */
class MyContentArbitraryFacet extends ArbitraryFacetBase {

  /**
   * {@inheritdoc}
   */
  public function getFacetDefinition() {
    $current_user = \Drupal::currentUser();

    $definition = [
      'featured' => [
        'field_name' => 'site_featured',
        'field_condition' => 'true',
        'label' => $this->t('Featured content'),
      ],
    ];

    if (!$current_user->isAnonymous()) {
      $definition['mine'] = [
        'field_name' => 'entity_author',
        'field_condition' => $current_user->id(),
        'label' => $this->t('My content'),
      ];
    }

    return $definition;
  }

}
