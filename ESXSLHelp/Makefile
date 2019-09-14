# The following environment variables are required:
# BUNDLE_ID Bundle ID of project
BUNDLE_ID = com.mycompany.myapp.help

# APP_NAME Name of project
APP_NAME = myapp

# Default output files
HTML = about features releasenotes usage support credits

# The following environment variables may be defined:
# IMAGES Images to copy
# CSS CSS files to copy
# XSLT_PARAMS Additional XSLT parameters
# MORE_HTML Addition output files

# Xcode should override this
SRCROOT = .
INFOPLIST_NAME = Info.plist

# The project root.
HELP_PROJECT_DIR = $(SRCROOT)

BUNDLE = ../$(BUNDLE_ID)

# Find all localizations.
LOCALIZATIONS = $(notdir $(shell /usr/bin/find $(HELP_PROJECT_DIR) -type d -depth 1 -regex ".*..\.lproj"))
LOCALIZATION_TARGETS = $(addprefix $(BUNDLE)/Contents/Resources/,$(LOCALIZATIONS))

# Create a list of targets that need to be copied.
copytargets = $(addprefix $(LOCALIZED_DESTINATION)/,$(IMAGES) $(CSS) $(SCRIPT))

.PHONY: build clean

build: preclean $(LOCALIZATION_TARGETS)
	mkdir -p $(BUNDLE)/Contents/Resources/shrd
	cp $(HELP_PROJECT_DIR)/$(INFOPLIST_NAME) $(BUNDLE)/Contents/Info.plist
	cp $(HELP_PROJECT_DIR)/images/*.png $(BUNDLE)/Contents/Resources/shrd

preclean:
	rm -Rf $(BUNDLE)

clean:
	rm -Rf $(BUNDLE)

install: build

$(BUNDLE)/Contents/Resources/%.lproj : $(localized_files) $(localized_index)
	-echo Building $*
	BUNDLE="$(BUNDLE)" \
  LANGUAGE="$*" \
  HELP_PROJECT_DIR="$(HELP_PROJECT_DIR)" \
  XSLT_PARAMS="$(XSLT_PARAMS)" \
  HTML="$(HTML)" \
  $(MAKE) -f Makefile.localized $(MAKECMDGOALS)

