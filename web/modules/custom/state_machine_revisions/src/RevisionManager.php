<?php

namespace Drupal\state_machine_revisions;

use Drupal\Core\Entity\ContentEntityInterface;
use Drupal\Core\Entity\EntityTypeInterface;
use Drupal\Core\Entity\EntityTypeManagerInterface;

/**
 * Manages stuff.
 */
class RevisionManager implements RevisionManagerInterface {

  /**
   * The entity type manager.
   *
   * @var \Drupal\Core\Entity\EntityTypeManagerInterface
   */
  protected $entityTypeManager;

  /**
   * Constructs a new RevisionManager object.
   *
   * @param \Drupal\Core\Entity\EntityTypeManagerInterface $entityTypeManager
   *   The entity type manager.
   */
  public function __construct(EntityTypeManagerInterface $entityTypeManager) {
    $this->entityTypeManager = $entityTypeManager;
  }

  /**
   * {@inheritdoc}
   */
  public function getLatestRevisionId(ContentEntityInterface $entity) {
    $entity_type = $entity->getEntityTypeId();

    if ($storage = $this->entityTypeManager->getStorage($entity_type)) {
      $revision_ids = $storage->getQuery()
        ->allRevisions()
        ->condition($this->entityTypeManager->getDefinition($entity_type)->getKey('id'), $entity->id())
        ->sort($this->entityTypeManager->getDefinition($entity_type)->getKey('revision'), 'DESC')
        ->range(0, 1)
        ->execute();
      if ($revision_ids) {
        return array_keys($revision_ids)[0];
      }
    }

    return NULL;
  }

  /**
   * {@inheritdoc}
   */
  public function isRevisionableEntityType(EntityTypeInterface $entityType) {
    return $entityType->isRevisionable();
  }

  /**
   * {@inheritdoc}
   */
  public function isLatestRevision(ContentEntityInterface $entity) {
    return $entity->getRevisionId() == $this->getLatestRevisionId($entity);
  }

  /**
   * {@inheritdoc}
   */
  public function loadLatestRevision(ContentEntityInterface $entity) {
    if ($latest_revision_id = $this->getLatestRevisionId($entity)) {
      return $this->entityTypeManager->getStorage($entity->getEntityTypeId())->loadRevision($latest_revision_id);
    }

    return NULL;
  }

}
