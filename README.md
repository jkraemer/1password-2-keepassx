# 1Password to KeepassX migration script

Simple script to convert the JSON like data exported by
1Password to KeepassX v1 XML.

## Usage

1password_2_keepassx.rb < 1password.1pif > keepassx.xml

## KeepassX groups and icons

The script makes some efforts to map the 1Password categories
to different KeepassX groups with corresponding icons.
However I stopped tweaking this mapping when the result was
'good enough' for me. Your mileage may vary, feel free to
adjust the code to suit your needs.

## License

MIT License, see LICENSE.txt
Copyright 2013 Jens Kraemer <jk@jkraemer.net>
