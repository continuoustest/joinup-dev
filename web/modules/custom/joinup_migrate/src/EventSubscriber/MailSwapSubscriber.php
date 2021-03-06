<?php

namespace Drupal\joinup_migrate\EventSubscriber;

use Drupal\migrate\Event\MigrateEvents;
use Drupal\migrate\Event\MigrateImportEvent;
use Drupal\migrate\Event\MigrateRollbackEvent;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

/**
 * A subscriber that swaps out the system mail during migration.
 */
class MailSwapSubscriber implements EventSubscriberInterface {

  /**
   * {@inheritdoc}
   */
  public static function getSubscribedEvents() {
    return [
      MigrateEvents::PRE_IMPORT => 'importToggleMailOff',
      MigrateEvents::POST_IMPORT => 'importToggleMailOn',
      MigrateEvents::PRE_ROLLBACK => 'rollbackToggleMailOff',
      MigrateEvents::POST_ROLLBACK => 'rollbackToggleMailOn',
    ];
  }

  /**
   * Switches mailing off on import.
   *
   * @param \Drupal\migrate\Event\MigrateImportEvent $event
   *   The event object.
   */
  public function importToggleMailOff(MigrateImportEvent $event) {
    $this->toggleMailOff();
  }

  /**
   * Switches mailing off on rollback.
   *
   * @param \Drupal\migrate\Event\MigrateRollbackEvent $event
   *   The event object.
   */
  public function rollbackToggleMailOff(MigrateRollbackEvent $event) {
    $this->toggleMailOff();
  }

  /**
   * Restores mailing after import.
   *
   * @param \Drupal\migrate\Event\MigrateImportEvent $event
   *   The event object.
   */
  public function importToggleMailOn(MigrateImportEvent $event) {
    $this->toggleMailOn();
  }

  /**
   * Restores mailing after rollback.
   *
   * @param \Drupal\migrate\Event\MigrateRollbackEvent $event
   *   The event object.
   */
  public function rollbackToggleMailOn(MigrateRollbackEvent $event) {
    $this->toggleMailOn();
  }

  /**
   * Switches mailing off.
   */
  protected function toggleMailOff() {
    $config_factory = \Drupal::configFactory();
    // Switch to 'null' mailer.
    $config_factory->getEditable('system.mail')
      ->set('interface.default', 'null')->save();
    $config_factory->getEditable('mailsystem.settings')
      ->set('defaults.sender', 'null')->save();
  }

  /**
   * Switches mailing back on.
   */
  protected function toggleMailOn() {
    $config_factory = \Drupal::configFactory();
    // Restore the system mailer.
    $config_factory->getEditable('system.mail')
      ->set('interface.default', 'php_mail')->save();
    $config_factory->getEditable('mailsystem.settings')
      ->set('defaults.sender', 'swiftmailer')->save();
  }

}
