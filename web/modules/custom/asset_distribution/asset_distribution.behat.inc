<?php

/**
 * @file
 * Contains \AssetDistributionSubContext.
 */

use Behat\Gherkin\Node\TableNode;
use Drupal\Component\Utility\UrlHelper;
use Drupal\DrupalExtension\Context\DrupalSubContextBase;
use Drupal\DrupalExtension\Context\DrupalSubContextInterface;
use Drupal\joinup\Traits\EntityReferenceTrait;
use Drupal\joinup\Traits\FileTrait;
use Drupal\joinup\Traits\RdfEntityTrait;
use Drupal\og\OgGroupAudienceHelperInterface;
use Drupal\rdf_entity\Entity\Rdf;
use Drupal\file_url\FileUrlHandler;

/**
 * Behat step definitions for testing asset distributions.
 */
class AssetDistributionSubContext extends DrupalSubContextBase implements DrupalSubContextInterface {

  use FileTrait;
  use RdfEntityTrait;
  use EntityReferenceTrait;

  /**
   * Test asset distributions.
   *
   * @var \Drupal\rdf_entity\Entity\Rdf[]
   */
  protected $assetDistributions = [];

  /**
   * Navigates to the canonical page display of an asset distribution.
   *
   * @param string $asset_distribution
   *   The title of the asset distribution.
   *
   * @When (I )go to (the homepage of )the :asset_distribution distribution
   * @When (I )visit (the homepage of )the :asset_distribution distribution
   */
  public function visitDistribution($asset_distribution) {
    /** @var \Drupal\rdf_entity\Entity\Rdf $asset_distribution */
    $asset_distribution = $this->getAssetDistributionByName($asset_distribution);
    $this->visitPath($asset_distribution->url());
  }

  /**
   * Navigates to the edit form of an asset distribution.
   *
   * @param string $asset_distribution
   *   The title of the $asset_distribution.
   *
   * @When (I )go to the :asset_distribution asset distribution edit form
   * @When (I )visit the :asset_distribution asset distribution edit form
   */
  public function visitEditAssetDistribution($asset_distribution) {
    /** @var \Drupal\rdf_entity\Entity\Rdf $asset_distribution */
    $asset_distribution = $this->getAssetDistributionByName($asset_distribution);
    $path = $asset_distribution->url('edit-form');
    $this->visitPath($path);
  }

  /**
   * Creates a number of asset distributions with data provided in a table.
   *
   * @param \Behat\Gherkin\Node\TableNode $asset_distribution_table
   *   The asset distribution data.
   *
   * @codingStandardsIgnoreStart
   *   Table format:
   *   | uri                                     | title            | description                | access url                               | creation date     | modification date | parent        |
   *   | http://joinup.eu/asset_distribution/foo | Foo distribution | This is a foo distribution | test.zip                                 | 28-01-1995 12:05  | 30-01-1995 10:44  | Solution name |
   *   | http://joinup.eu/asset_distribution/bar | Bar distribution | This is a bar distribution | http://external_url.com/path-to-file.zip | 28-01-1995 12:06  |                   | Release name  |
   * @codingStandardsIgnoreEnd
   *
   * Fields title and description are mandatory. Field 'access url' can be
   * either an external valid URL or a local file to be uploaded.
   *
   * @throws \Exception
   *   Thrown when a column name is incorrect.
   *
   * @Given (the following )(asset )distributions:
   */
  public function givenAssetDistributions(TableNode $asset_distribution_table) {
    foreach ($asset_distribution_table->getColumnsHash() as $values) {
      $this->createAssetDistributionFromAliasedTableValues($values);
    }
  }

  /**
   * Creates an asset distribution with data provided in a table.
   *
   * Table format:
   * | title       | Sample distribution                             |
   * | uri         | http://joinup.eu/distribution/foobar            |
   * | description | A sample distribution                           |
   * | access url  | http://external.path/to/file.zip  (or test.zip) |
   * | parent      | Release or solution name                        |
   *
   * Fields 'title' and 'description' are required. Field 'access url' can be
   * either an external valid URL or a local file to be uploaded.
   *
   * @param \Behat\Gherkin\Node\TableNode $asset_distribution_table
   *   The asset distribution data.
   *
   * @throws \Exception
   *   Thrown when a column name is incorrect.
   *
   * @Given (the following )(asset )distribution:
   */
  public function givenAssetDistribution(TableNode $asset_distribution_table) {
    $values = $asset_distribution_table->getRowsHash();
    $this->createAssetDistributionFromAliasedTableValues($values);
  }

  /**
   * Creates an asset distribution from the given property and field data.
   *
   * @param array $values
   *   An optional associative array of values, keyed by property name.
   *
   * @return \Drupal\rdf_entity\Entity\Rdf
   *   A new asset distribution entity.
   *
   * @throws \Exception
   *   Thrown when a given file is not found.
   */
  protected function createAssetDistribution(array $values) {
    // The Access URL field is either an external URI, or file upload.
    if (!empty($values['field_ad_access_url'])) {
      global $base_url;
      foreach ($values['field_ad_access_url'] as $key => $url) {
        if (!UrlHelper::isValid($url, TRUE) || !UrlHelper::isExternal($url) || UrlHelper::externalIsLocal($url, $base_url)) {
          // It's a local file to be uploaded.
          $values['field_ad_access_url'][$key] = FileUrlHandler::fileToUrl($this->createFile($url));
        }
      }
    }

    $asset_distribution = $this->createRdfEntity('asset_distribution', $values);
    $this->assetDistributions[$asset_distribution->id()] = $asset_distribution;

    return $asset_distribution;
  }

  /**
   * Creates an asset distribution using the provided aliases table values.
   *
   * @param array $aliased_values
   *   An associative array of values used to create the distribuion, with keys
   *   using the aliases from self::assetDistributionFieldAliases(). If the key
   *   'parent' is present, a relation with a parent solution or release with
   *   a label matching this value will be created.
   *
   * @throws \Exception
   *   Thrown when an unknown key alias is present in the list of values.
   */
  protected function createAssetDistributionFromAliasedTableValues(array $aliased_values) {
    $aliases = self::assetDistributionFieldAliases();

    $values = [];
    // Replace the column aliases with the actual field names.
    foreach ($aliased_values as $key => $value) {
      if (array_key_exists($key, $aliases)) {
        $values[$aliases[$key]] = $value;
      }
      // If the 'parent' key is present we will have to create a relation to the
      // parent entity, which is either a release or a solution.
      elseif ($key === 'parent') {
        $parent_entity = self::getRdfEntityByLabel($value);

        // If we know the parent then we can transparently populate the group
        // reference to the solution.
        if (!array_key_exists('solution', $aliased_values)) {
          $solution_label = NULL;
          if ($parent_entity->bundle() === 'solution') {
            $solution_label = $parent_entity->label();
          }
          elseif ($solution_entity_id = $parent_entity->field_isr_is_version_of->value) {
            $solution_label = Rdf::load($solution_entity_id)->label();
          }
          $values[OgGroupAudienceHelperInterface::DEFAULT_FIELD] = $solution_label;
        }
      }
      else {
        throw new \Exception("Unknown key '$key' in asset distribution table.");
      }
    };

    $values = $this->convertValueAliases($values);
    $values = $this->convertEntityReferencesValues('rdf_entity', 'asset_distribution', $this->parseRdfEntityFields($values));
    $asset_distribution_entity = $this->createAssetDistribution($values);

    // Create the relation with the parent entity if requested.
    if (!empty($parent_entity)) {
      asset_distribution_add_parent_relation($asset_distribution_entity, $parent_entity);
    }
  }

  /**
   * Deletes an asset distribution.
   *
   * @param string $asset_distribution
   *   The title of the asset distribution.
   *
   * @When (I )delete the :asset_distribution asset distribution
   */
  public function deleteAssetDistribution($asset_distribution) {
    /** @var \Drupal\rdf_entity\Entity\Rdf $asset_distribution */
    $asset_distribution = $this->getAssetDistributionByName($asset_distribution);
    $asset_distribution->skip_notification = TRUE;
    $asset_distribution->delete();
  }

  /**
   * Returns the asset distribution with the given title.
   *
   * If multiple asset distributions have the same title,
   * the first one will be returned.
   *
   * @param string $title
   *   The asset distribution title.
   *
   * @return \Drupal\rdf_entity\Entity\Rdf
   *   The asset distribution.
   *
   * @throws \InvalidArgumentException
   *   Thrown when an asset distribution with the given title does not exist.
   */
  protected function getAssetDistributionByName($title) {
    return $this->getRdfEntityByLabel($title, 'asset_distribution');
  }

  /**
   * Returns the Solution with the given title.
   *
   * If multiple solution have the same title, the first one will be returned.
   *
   * @param string $title
   *   The solution title.
   *
   * @return \Drupal\rdf_entity\Entity\Rdf
   *   The solution.
   *
   * @throws \InvalidArgumentException
   *   Thrown when a solution with the given title does not exist.
   */
  protected function getSolutionByName($title) {
    return $this->getRdfEntityByLabel($title, 'solution');
  }

  /**
   * Checks the number of available asset distributions.
   *
   * @param int $number
   *   The expected number of asset distributions.
   *
   * @Then I should have :number distribution(s)
   */
  public function assertAssetDistributionCount($number) {
    $this->assertRdfEntityCount($number, 'asset_distribution');
  }

  /**
   * Navigates to the canonical page display of an asset distribution.
   *
   * @param string $title
   *   The title of the asset distribution.
   *
   * @When (I )go to (the homepage of )the :asset_distribution asset distribution
   * @When (I )visit (the homepage of )the :asset_distribution asset distribution
   */
  public function visitAssetDistribution($title) {
    $distribution = $this->getAssetDistributionByName($title);
    $this->visitPath($distribution->url());
  }

  /**
   * Remove any created asset distributions.
   *
   * @AfterScenario
   */
  public function cleanAssetDistributions() {
    // Remove any asset distributions that were created.
    foreach ($this->assetDistributions as $asset_distribution) {
      $asset_distribution->skip_notification = TRUE;
      $asset_distribution->delete();
    }
  }

  /**
   * Field alias mapping.
   *
   * @return array
   *   Mapping.
   */
  protected static function assetDistributionFieldAliases() {
    // Mapping alias - field name.
    return [
      'access url' => 'field_ad_access_url',
      'creation date' => 'created',
      'description' => 'field_ad_description',
      'downloads' => 'field_download_count',
      'file size' => 'field_ad_file_size',
      'format' => 'field_ad_format',
      'licence' => 'field_ad_licence',
      'modification date' => 'changed',
      'representation technique' => 'field_ad_repr_technique',
      'solution' => OgGroupAudienceHelperInterface::DEFAULT_FIELD,
      'status' => 'field_status',
      'title' => 'label',
      'uri' => 'id',
    ];
  }

  /**
   * Converts values from user friendly to normal machine values.
   *
   * @param array $fields
   *   An array of fields keyed by field name.
   *
   * @return array
   *   The array with the values converted.
   */
  protected function convertValueAliases(array $fields) {
    if (!empty($fields[OgGroupAudienceHelperInterface::DEFAULT_FIELD])) {
      $solution = $this->getRdfEntityByLabel($fields[OgGroupAudienceHelperInterface::DEFAULT_FIELD], 'solution');
      $fields[OgGroupAudienceHelperInterface::DEFAULT_FIELD] = $solution->id();
    }

    return $fields;
  }

  /**
   * Checks if a distribution in compact view contains download links.
   *
   * The compact view is used for example in the "Downloads" page.
   * This currently only checks the first download link.
   *
   * @param string $distribution
   *   The name of the distribution.
   *
   * @throws \Exception
   *   Thrown if the download link cannot be found.
   *
   * @Then I should see the download link in the :distribution( asset) distribution
   */
  public function assertLinkPresentInCompactDistributionTile($distribution) {
    $distribution = $this->getAssetDistributionByName($distribution);
    if (empty($distribution->field_ad_access_url->first())) {
      throw new \Exception(sprintf('Asset distribution "%s" does not contain any download links.', $distribution->label()));
    }
    $file = FileUrlHandler::urlToFile($distribution->field_ad_access_url->target_id);
    $link = FileUrlHandler::isRemote($file) ? $distribution->field_ad_access_url->target_id : file_create_url($file->getFileUri());
    $result = $this->getSession()->getPage()->find('xpath', "//a[contains(., '{$distribution->label()}')]/ancestor::div[contains(concat(' ', @class, ' '), ' timeline__listing-item ')]//a[@href='{$link}']");
    if (empty($result)) {
      throw new \Exception(sprintf('No link was found in the "%s" distribution on the page %s', $distribution->label(), $this->getSession()->getCurrentUrl()));
    }
  }

  /**
   * Checks that a distribution in compact view does not contain download links.
   *
   * The compact view is used for example in the "Downloads" page.
   *
   * @param string $distribution
   *   The name of the distribution.
   *
   * @throws \Exception
   *   Thrown if the link was found.
   *
   * @Then the :distribution( asset) distribution should not have any download urls
   */
  public function assertLinkNotPresentInCompactDistributionTile($distribution) {
    $link = $this->getSession()->getPage()->find('xpath', "//a[contains(text(), '$distribution')]/ancestor::div[contains(concat(' ', @class, ' '), ' timeline__listing-item ')]//span[contains(concat(' ', @class, ' '), ' file ')]/a");
    if (!empty($link)) {
      throw new \Exception(sprintf('Asset distribution "%s" contains download link(s).', $distribution));
    }
  }

  /**
   * Asserts that a file is attached to a distribution.
   *
   * @param string $distribution
   *   The distribution title.
   * @param string $file_name
   *   The file name.
   *
   * @throws \Exception
   *    Thrown when the file or the link is not found.
   *
   * @Then the :distribution distribution should have the link of the :file_name in the access URL field
   */
  public function assertLinkSynchronized($distribution, $file_name) {
    $distribution = $this->getAssetDistributionByName($distribution);
    $file = FileUrlHandler::urlToFile($distribution->field_ad_access_url->target_id);
    if (($file->getFilename() !== $file_name) || !file_create_url($file->getFileUri())) {
      throw new \Exception("The file {$file_name} was not found in the '{$distribution->label()}' distribution'");
    }

    $files_path = $this->getMinkParameter('files_path');
    $path = rtrim(realpath($files_path), DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $file_name;
    if (!is_file($path)) {
      throw new \Exception("File '$file_name' was not found in file path '$files_path'.");
    }

    /** @var \Symfony\Component\HttpFoundation\File\MimeType\MimeTypeGuesserInterface $mime_guesser */
    $mime_guesser = \Drupal::service('file.mime_type.guesser');
    $mime_type = $mime_guesser->guess($path);
    $expected_file_type = asset_distribution_get_file_type_term_by_mime($mime_type);
    $expected_file_size = filesize($path);

    // Test the file format.
    if ($expected_file_type !== $distribution->field_ad_format->target_id) {
      throw new \Exception("File '$file_name' has the format '{$distribution->field_ad_format->target_id}'. Expected '$expected_file_type'.");
    }

    // Test the file size.
    if ($expected_file_size !== (int) $distribution->field_ad_file_size->value) {
      throw new \Exception("File '$file_name' has the size '{$distribution->field_ad_file_size->value}'. Expected '$expected_file_size'.");
    }
  }

  /**
   * Uploads a file or sets a remote URL to a 'file_url' field.
   *
   * @param string $file_or_url
   *   Either file name to be uploaded or a remote URL.
   * @param string $file_url_field
   *   The file URL field label.
   *
   * @throws \Exception
   *   The file to be uploaded doesn't exists.
   *
   * @Given I upload the file :file_or_url to :file_url_field
   * @Given I set a remote URL :file_or_url to :file_url_field
   */
  public function addFileUrlItem($file_or_url, $file_url_field) {
    $type = UrlHelper::isExternal($file_or_url) ? 'remote' : 'upload';

    $session = $this->getSession();
    $page = $session->getPage();

    // Locate the file URL field widget wrapper.
    $wrapper = $page->find('xpath', "//label[text()='$file_url_field']/ancestor::div[contains(concat(' ', normalize-space(@class), ' '), ' field--type-file-url ')][1]");
    if (!$wrapper) {
      throw new \Exception("Cannot find the file URL field '$file_url_field'.");
    }

    /** @var \Behat\Mink\Element\NodeElement $radio */
    $radio = $wrapper->find('xpath', "//input[@type='radio']");
    if (!$radio) {
      throw new \Exception("Malformed file URL field '$file_url_field': Can't find the inner radio option.");
    }
    $page->selectFieldOption($radio->getAttribute('name'), $type);

    if ($type === 'upload') {
      // Qualify the file path.
      $files_path = $this->getMinkParameter('files_path');
      $path = rtrim(realpath($files_path), DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $file_or_url;
      if (!is_file($path)) {
        throw new \Exception("File '$file_or_url' was not found in file path '$files_path'.");
      }
      $wrapper->attachFileToField('Choose a file', $path);
    }
    elseif ($type === 'remote') {
      $wrapper->fillField('Remote URL', $file_or_url);
    }
  }

  /**
   * Clicks a link inside a distribution rendered with the compact view mode.
   *
   * @param string $link
   *   The text of the link to click.
   * @param string $heading
   *   The distribution title.
   *
   * @throws \Exception
   *   Thrown when the rendered distribution is not found.
   *
   * @When I click :link in the :heading asset distribution
   */
  public function clickLinkInCompactDistribution($link, $heading) {
    $element = $this->getCompactDistributionByHeading($heading);

    if (!$element) {
      throw new \Exception("The tile '$heading' was not found on the page.");
    }

    $element->clickLink($link);
  }

  /**
   * Asserts the entries in the download event table.
   *
   * Table format:
   * @codingStandardsIgnoreStart
   * | user                     | e-mail                | distribution |
   * | Anonymous (not verified) | mail1@example.com     | Distro one   |
   * | Nickolas Underwood       | underwood@example.com | Distro two   |
   * @codingStandardsIgnoreEnd
   *
   * @param \Behat\Gherkin\Node\TableNode $table
   *   The entries list.
   *
   * @Then I should see the following download entries:
   */
  public function assertDownloadEventEntries(TableNode $table) {
    $base_selector = '.distribution-download-table table > tbody > tr';
    $count = 0;
    foreach ($table->getColumnsHash() as $entry) {
      $count++;
      $selector = $base_selector . ":nth-child({$count})";

      $this->assertSession()->elementTextContains('css', $selector, $entry['user']);
      $this->assertSession()->elementTextContains('css', $selector, $entry['e-mail']);
      $this->getSession()->getPage()->find('css', $selector)->hasLink($entry['distribution']);
    }
  }

  /**
   * Navigates to the distribution downloads statistics page.
   *
   * @When I go to the distribution downloads page
   */
  public function goToDistributionDownloadsPage() {
    $this->visitPath('admin/statistics/distribution-downloads');
  }

  /**
   * Finds a distribution rendered with the compact view mode by its heading.
   *
   * @param string $heading
   *   The heading of the distribution to find.
   *
   * @return \Behat\Mink\Element\NodeElement|null
   *   The compact distribution element, or null if not found.
   */
  protected function getCompactDistributionByHeading($heading) {
    // Locate all the elements.
    $xpath = '//*[@class and contains(concat(" ", normalize-space(@class), " "), " timeline__listing-item ")]';
    // That have a heading with the specified text.
    $xpath .= '[.//*[@class and contains(concat(" ", normalize-space(@class), " "), " timeline__listing-title ")][normalize-space()="' . $heading . '"]]';

    return $this->getSession()->getPage()->find('xpath', $xpath);
  }

}
