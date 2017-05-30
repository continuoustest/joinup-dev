<?php

namespace Drupal\joinup_migrate\Plugin\migrate\source;

use Drupal\migrate\Row;

/**
 * Attaches files to nodes.
 */
trait AttachmentTrait {

  /**
   * Attaches files to row.
   *
   * @param \Drupal\migrate\Row $row
   *   The source row.
   */
  protected function setAttachment(Row &$row) {
    $fids = NULL;
    $row->setSourceProperty('fids', $fids);
  }

}
