# == Define: mediawiki::skin
#
# This resource type represents a MediaWiki skin. Declaring a skin to
# Puppet will cause Puppet to retrieve the skin code from Gerrit and
# configure MediaWiki to load it.
#
# === Parameters
#
# [*ensure*]
#   If 'present' (the default), Puppet will install the skin. If
#   'absent', Puppet will delete its configuration file, but it will not
#   delete the cloned Git repository which contains the extension's
#   files.
#
# [*wiki*]
#   Wiki to add settings for. The default will install the settings for all
#   wikis. The wiki name can also be specified in the resource's title as
#   'wiki:rest_of_title'.
#
# [*skin*]
#   The canonical (CamelCase) name for the skin. This value is used to
#   generate sensible defaults for the installation path and Gerrit
#   repository name. Defaults to the resource title.
#
# [*default*]
#   When set to true, the skin will be used as the default for anonymous
#   users and logged-in users who did not change their defaults. When
#   more then one skin resource sets this flag, the behavior is undefined.
#
# [*branch*]
#   Specifies which branch of the skin's Git repository should be cloned.
#   Defaults to 'master'.
#
# [*settings*]
#   This parameter contains configuration settings for the skin.
#   Settings may be specified as a hash, array, or string. See examples
#   below. Empty by default.
#
# === Examples
#
# The following example configures the Vector skin and
# illustrates the use of hashes to specify settings:
#
#   mediawiki::skin { 'Vector':
#     settings => {
#       wgVectorUseSimpleSearch => false,
#     },
#   }
#
define mediawiki::skin(
    $ensure         = present,
    $wiki           = undef,
    $skin           = $title,
    $default        = false,
    $branch         = undef,
    $settings       = {},
) {
    include ::mediawiki

    $skin_dir = "${mediawiki::dir}/skins/${skin}"

    if ! defined(Git::Clone["mediawiki/skins/${skin}"]) {
        git::clone { "mediawiki/skins/${skin}":
            directory => $skin_dir,
            branch    => $branch,
            require   => Git::Clone['mediawiki/core'],
        }
    }

    mediawiki::settings { $title:
        ensure       => $ensure,
        wiki         => $wiki,
        header       => template('mediawiki/skin.php.erb'),
        values       => $settings,
        require      => Git::Clone["mediawiki/skins/${skin}"],
    }
}
