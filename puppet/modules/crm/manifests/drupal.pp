# == Class: crm::drupal
#
# Drupal and modules
#
# === Parameters
#
# [*modules*]
#   Array of all modules that should be enabled
#
# [*settings*]
#   Map from drupal variable names to default values.
#
class crm::drupal(
    $modules,
    $settings = {},
) {
    include ::crm

    $files_dir = '/srv/org.wikimedia.civicrm-files'
    $dir = "${crm::dir}/drupal"

    $install_script = "${dir}/sites/default/drupal-install.php"
    $settings_path = "${dir}/sites/default/settings.php"

    $databases = [
        $::crm::drupal_db,
        'donations',
        'fredge',
    ]

    $db_url = "mysql://${::crm::db_user}:${::crm::db_pass}@localhost/${::crm::drupal_db}"

    class { 'crm::drush':
        root => $dir,
    }

    file { $files_dir:
        ensure    => directory,
        group     => 'www-data',
        mode      => '2775',
        recurse   => true,
        subscribe => Exec['civicrm_setup'],
    }

    file { "${dir}/sites/default/files":
        ensure    => link,
        target    => $files_dir,
        force     => true,
        subscribe => Exec['drupal_db_install'],
    }

    file { $install_script:
        content => template('crm/drupal-install.sh.erb'),
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0750',
        require => Git::Clone[$::crm::repo],
    }

    mysql::db { $databases: }

    exec { 'drupal_db_install':
        command => $install_script,
        unless  => "mysql -u '${::crm::db_user}' -p'${::crm::db_pass}' '${::crm::drupal_db}' -e 'select 1 from system'",
        require => [
            Git::Clone[$::crm::repo],
            Mysql::Db[$databases],
            Package['drush'],
        ],
    }

    file { $settings_path:
        content => template('crm/settings.php.erb'),
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
        require => Git::Clone[$::crm::repo],
    }

    exec { 'enable_drupal_modules':
        command => inline_template('<%= scope["::crm::drush::cmd"] %> pm-enable <%= @modules.join(" ") %>'),
        require => [
            Exec['drupal_db_install'],
            Exec['civicrm_setup'],
            File[$settings_path],
        ],
    }
}
