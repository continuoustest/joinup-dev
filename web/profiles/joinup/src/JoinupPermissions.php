<?php

namespace Drupal\joinup;

use Drupal\Core\StringTranslation\StringTranslationTrait;
use Drupal\rdf_entity\Entity\RdfEntityType;

/**
 * Provides dynamic permissions for the Joinup installation profile.
 */
class JoinupPermissions {

  use StringTranslationTrait;

  /**
   * Returns an array of permissions related to Rdf types.
   *
   * The Joinup profile alters a new form display mode into the Rdf entity type,
   * and this provides permissions to use those forms for each type.
   *
   * @return array
   *   The permissions.
   *
   * @see \Drupal\user\PermissionHandlerInterface::getPermissions()
   * @see joinup_entity_type_alter()
   */
  public function rdfTypePermissions() {
    $perms = [];
    $types = RdfEntityType::loadMultiple();
    // Generate permissions to propose rdf entities of all types.
    /** @var EntityTypeInterface $type */
    foreach ($types as $type) {
      $perms += $this->buildProposeRdfTypePermissions($type);
      if ($type->id() != 'collection') {
        $perms += $this->buildGroupRdfTypePermissions($type);
      }
    }

    return $perms;
  }

  /**
   * Returns a list of propose permissions for a given Rdf entity type.
   *
   * @param \Drupal\rdf_entity\Entity\RdfEntityType $type
   *   The Rdf type.
   *
   * @return array
   *   An associative array of permission names and descriptions.
   */
  protected function buildProposeRdfTypePermissions(RdfEntityType $type) {
    $type_id = $type->id();
    $type_params = ['%type_name' => $type->label()];

    return [
      "create group $type_id rdf entity" => [
        'title' => $this->t('%type_name: Propose new rdf entity', $type_params),
      ],
    ];
  }

  /**
   * Returns a list of permissions for a given Rdf entity type.
   *
   * These permissions refer to access the create page from within the group.
   *
   * @param \Drupal\rdf_entity\Entity\RdfEntityType $type
   *   The Rdf type.
   *
   * @return array
   *   An associative array of permission names and descriptions.
   */
  protected function buildGroupRdfTypePermissions(RdfEntityType $type) {
    $type_id = $type->id();
    $type_params = ['%type_name' => $type->label()];

    return [
      "propose $type_id rdf entity" => [
        'title' => $this->t('%type_name: Create group rdf entity', $type_params),
      ],
    ];
  }

}
