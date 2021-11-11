DOTFILES_DIR := $(HOME)/.dotfiles
UNAME        := $(shell uname -s)
BREW_CHECK 	 := type brew >/dev/null 2>/dev/null || $(MAKE) brew

ifeq ($(UNAME), Darwin)
  OS := macos
else ifeq ($(UNAME), Linux)
  OS := linux
endif

.PHONY: \
	bash \
	brew \
	defaults \
	hosts \
	install \
	linux \
	macos \
	node \
	stow \
	vsc \
	zsh

install: $(OS) ## Default install all by OS.

help:
	@echo 'Usage:'
	@echo '    make <target>'
	@echo
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[0m%-10s\033[0m %s\n", $$1, $$2}'

linux: ## TBD (Manually install everything for Linux.)

macos: ## Manually install everything for MacOS.
	@echo 'Installing for MacOS...'
	$(MAKE) brew
	$(MAKE) bash
	$(MAKE) zsh
	$(MAKE) node
	$(MAKE) vsc
	$(MAKE) stow
	$(MAKE) defaults
	[ -d $(HOME)/.ssh/config ] || mkdir -p $(HOME)/.ssh/config
	softwareupdate -d -a

brew: /usr/local/bin/brew ## Install brew and all applications.
	@echo 'Updating all brew packages...'
	brew update --verbose
	brew upgrade --verbose
	brew cleanup -s
	brew bundle

/usr/local/bin/brew:
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
	brew analytics off

bash: ## Install an updated Bash shell.
	$(BREW_CHECK)
	@echo 'Updating bash...'
	stow bash --restow

	# change shell to homebrew bash
	echo "/usr/local/bin/bash" | sudo tee -a /etc/shells
	chsh -s /usr/local/bin/bash

zsh: ## Install an updated Zsh shell and theming.
	$(BREW_CHECK)
	@echo 'Updating zsh / refreshing themes...'
	@rm -rf ~/.oh-my-zsh
	sh -c "$$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" </dev/null
	@rm ~/.zshrc

	git clone https://github.com/romkatv/powerlevel10k.git "$(HOME)/.oh-my-zsh/custom/themes/powerlevel10k"
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$(HOME)/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
	git clone https://github.com/zsh-users/zsh-autosuggestions "$(HOME)/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

	stow zsh --restow

	# change shell to homebrew zsh
	echo "/usr/local/bin/zsh" | sudo tee -a /etc/shells
	chsh -s /usr/local/bin/zsh

node: ~/.nvm ## Install NVM and Node.
	@echo 'Updating NVM and Node...'
	# latest stable version of node
	. ~/.nvm/nvm.sh && nvm install stable

	# necessary npm packages for JS work
	. ~/.nvm/nvm.sh && npm install -g eslint express jshint jsxhint nodemon react-tools

~/.nvm:
	# setup node version manager
	git clone https://github.com/creationix/nvm.git ~/.nvm
	cd ~/.nvm && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`

vsc: ## Install all VSCode extensions.
	$(BREW_CHECK)
	@echo 'Install VSCode extensions'
	# Equivalent of VS [gui] Command Palette  "Shell command: Install 'code' command in PATH"
	ln -sf /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code /usr/local/bin/code

	# Helpful VScode extensions
	code --install-extension akamud.vscode-theme-onedark
	code --install-extension dbaeumer.vscode-eslint
	code --install-extension eamodio.gitlens
	code --install-extension eg2.tslint
	code --install-extension esbenp.prettier-vscode
	code --install-extension kumar-harsh.graphql-for-vscode
	code --install-extension mohsen1.prettify-json
	code --install-extension mrmlnc.vscode-duplicate
	code --install-extension ms-vscode.sublime-keybindings
	code --install-extension ryanluker.vscode-coverage-gutters
	## BE language support
	code --install-extension golang.go
	code --install-extension ms-python.python
	# Unity dev support
	code --install-extension ms-dotnettools.csharp
	code --install-extension tobiah.unity-tools
	code --install-extension unity.unity-debug
	code --install-extension kleber-swf.unity-code-snippets
	code --install-extension yclepticStudios.unity-snippets

hosts: ## Optionally set hosts file.
	@echo 'Set hosts file...'
	sudo wget https://someonewhocares.org/hosts/hosts -P /etc/

stow: ## Set all home file references.
	@echo 'Restowing home files...'
	[ -d $(HOME)/bin ] || mkdir -p $(HOME)/bin
	[ -d $(HOME)/.gnupg ] || mkdir -p $(HOME)/.gnupg
	[ -d $(HOME)/.ssh ] || mkdir -p $(HOME)/.ssh
	[ -d $(HOME)/.config/kitty ] || mkdir -p $(HOME)/.config/kitty

	stow bin -t $(HOME)/bin --restow
	stow .gnupg -t $(HOME)/.gnupg --restow
	stow home --restow
	stow kitty -t $(HOME)/.config/kitty --restow
	stow .ssh -t $(HOME)/.ssh --restow
	stow tmux --restow

defaults: ## Set OS defaults.
	$(MAKE) default-Apps
	$(MAKE) defaults-Dock
	$(MAKE) defaults-Finder
	$(MAKE) defaults-NSGlobalDomain

	# Show remaining battery time as percentage
	defaults write com.apple.menuextra.battery ShowPercent -string "YES"
	# Enable AirDrop over Ethernet and on unsupported Macs running Lion
	defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

	# Disable the “Are you sure you want to open this application?” dialog
	defaults write com.apple.LaunchServices LSQuarantine -bool false
	# Automatically quit printer app once the print jobs complete
	defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
	# Check for software updates daily, not just once per week
	defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

	# Automatically illuminate built-in MacBook keyboard in low light
	defaults write com.apple.BezelServices kDim -bool true
	# Turn off keyboard illumination when computer is not used for 5 minutes
	defaults write com.apple.BezelServices kDimTime -int 300

	# Save screenshots to the desktop
	defaults write com.apple.screencapture location -string "$(HOME)/Desktop"
	# Disable shadow in screenshots
	defaults write com.apple.screencapture disable-shadow -bool true
	# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
	defaults write com.apple.screencapture type -string "png"
	# Enable HiDPI display modes (requires restart)
	sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

	# Require password immediately after 5 seconds on sleep or screen saver begins
	defaults write com.apple.screensaver askForPassword -int 1
	defaults write com.apple.screensaver askForPasswordDelay -int 5

	# Only use UTF-8 in Terminal.app
	defaults write com.apple.terminal StringEncodings -array 4
	# Don’t display the annoying prompt when quitting iTerm
	defaults write com.googlecode.iterm2 PromptOnQuit -bool false
	# Prevent Photos from opening automatically when devices are plugged in
	defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

	# Disable the all too sensitive backswipe on trackpads
	defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
	defaults write com.google.Chrome.canary AppleEnableSwipeNavigateWithScrolls -bool false

	# Disable the all too sensitive backswipe on Magic Mouse
	defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false
	defaults write com.google.Chrome.canary AppleEnableMouseSwipeNavigateWithScrolls -bool false

	# disable apple captive portal (seucrity issue)
	# sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false

	# setup OpenDNS
	# networksetup -setdnsservers Wi-Fi 208.67.222.222 208.67.220.220

	# Kill affected applications
	@for app in Dock Safari Finder Photos SystemUIServer; do killall "$$app" >/dev/null 2>&1; done

default-Apps:
	$(BREW_CHECK)
	# default IINA (media files)
	@while read -r ext; do \
	  duti -s com.colliderli.iina "$ext" all; \
	done <"${DOTFILES_DIR}/.duti/iina.txt"

defaults-Dock:
	$(BREW_CHECK)
	# Automatically hide and show the Dock
	defaults write com.apple.dock autohide -bool true
	# Make Dock icons of hidden applications translucent
	defaults write com.apple.dock showhidden -bool true
	# Set the icon size of Dock items to 36 pixels
	defaults write com.apple.dock tilesize -int 36
	# Enable highlight hover effect for the grid view of a stack (Dock)
	defaults write com.apple.dock mouse-over-hilte-stack -bool true
	# Enable spring loading for all Dock items
	defaults write enable-spring-load-actions-on-all-items -bool true
	# Show indicator lights for open applications in the Dock
	defaults write com.apple.dock show-process-indicators -bool true
	# Don’t animate opening applications from the Dock
	defaults write com.apple.dock launchanim -bool false
	# Bottom left screen corner → Start screen saver
	defaults write com.apple.dock wvous-bl-corner -int 5
	defaults write com.apple.dock wvous-bl-modifier -int 0
	# Don't show recent applications in the Dock
	defaults write com.apple.dock show-recents -bool false
	defaults write com.apple.dock recent-apps -array

	dockutil --no-restart --remove all

	dockutil --no-restart --add "/Applications/Safari.app"
	dockutil --no-restart --add "/Applications/Google Chrome.app"
	dockutil --no-restart --add "/Applications/Brave Browser.app"
	dockutil --no-restart --add "/Applications/Firefox Developer Edition.app.app"
	dockutil --no-restart --add "/Applications/Evernote.app"
	dockutil --no-restart --add "/Applications/Notes.app"
	dockutil --no-restart --add "/Applications/Messages.app"
	dockutil --no-restart --add "/Applications/Facetime.app"
	dockutil --no-restart --add "/Applications/VirtualBox.app"
	dockutil --no-restart --add "/Applications/Visual Studio Code.app"
	dockutil --no-restart --add "/Applications/Kitty.app"
	dockutil --no-restart --add "/Applications/ExpressVPN.app"
	dockutil --no-restart --add "/Applications/System Preferences.app"

	dockutil --no-restart --add "/Applications" --section others --sort name --view grid
	dockutil --no-restart --add "$(HOME)/Downloads" --section others --view list

defaults-Finder:
	# Automatically open a new Finder window when a volume is mounted
	defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
	defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
	# Show icons for hard drives, servers, and removable media on the desktop
	defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
	defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
	defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
	defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
	# Finder: show status bar
	defaults write com.apple.finder ShowStatusBar -bool true
	# Finder: show path bar
	defaults write com.apple.finder ShowPathbar -bool true
	# When performing a search, search the current folder by default
	defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
	# Empty Trash securely by default
	defaults write com.apple.finder EmptyTrashSecurely -bool false
	# Avoid creating .DS_Store files on network or USB volumes
	defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
	defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
	# Show the ~/Library folder
	chflags nohidden $(HOME)/Library

defaults-NSGlobalDomain:
	# Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
	defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
	# Enable subpixel font rendering on non-Apple LCDs
	defaults write NSGlobalDomain AppleFontSmoothing -int 2
	# Set a blazingly fast keyboard repeat rate (1 = fastest for macOS high sierra, older versions support 0)
	defaults write NSGlobalDomain KeyRepeat -int 2
	# Decrase the time to initially trigger key repeat
	defaults write NSGlobalDomain InitialKeyRepeat -int 15
	# Set sidebar icon size to small
	defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1
	# Increase window resize speed for Cocoa applications
	defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
	# Save to disk (not to iCloud) by default
	defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
	# Disable smart quotes as they’re annoying when typing code
	defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
	# Disable smart dashes as they’re annoying when typing code
	defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
	# Finder: show all filename extensions
	defaults write NSGlobalDomain AppleShowAllExtensions -bool true
	# Expand save panel by default
	defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
	defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
	# Expand print panel by default
	defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
	defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
