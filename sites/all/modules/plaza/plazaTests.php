<?php 

// We assume that this script is being executed from the root of the Drupal
// installation. e.g. ~$ `phpunit TddTests sites/all/modules/tdd/TddTests.php`.
// These constants and variables are needed for the bootstrap process.
define('DRUPAL_ROOT', getcwd());
require_once DRUPAL_ROOT . '/includes/bootstrap.inc';
$_SERVER['REMOTE_ADDR'] = '127.0.0.1';


drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);

class plazaTests extends PHPUnit_Framework_TestCase {
    public function testEmptyMySQLDate() {

      $result = test_echo('toto');
      // Note: Test output messages should not be translated.
      $message = 'A toto value should return TRUE.';
      $this->assertEquals($result, 'toto');

      $result = test_echo('tata');
      // Note: Test output messages should not be translated.
      $message = 'A NULL value should return FALSE.';
      $this->assertEquals($result, 'tata');


  }
}

?>