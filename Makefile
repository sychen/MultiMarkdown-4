# This makefile works on Mac OS, Ubuntu, Fedora, and presumably other *.nix'es
# Feel free to submit pull requests if you have a proposed change.
# Please explain your change so I'll understand what you need, and why - 
# I don't claim to be an expert at this aspect! 
# - Fletcher T. Penney

CFLAGS ?= -Wall -g -O3 -include GLibFacade.h
PROGRAM = multimarkdown
VERSION = 4.2

OBJS= multimarkdown.o parse_utilities.o parser.o GLibFacade.o writer.o text.o html.o latex.o memoir.o beamer.o opml.o odf.o critic.o

GREG= greg/greg

ALL : $(PROGRAM) enumMap.txt

%.o : %.c parser.h
	gcc -c $(CFLAGS) -o $@ $<

parser.c : parser.leg greg/greg parser.h
	greg/greg -o parser.c parser.leg

$(GREG): greg
	touch greg/greg.c
	CC=gcc $(MAKE) -C greg

$(PROGRAM) : $(OBJS)
	gcc $(CFLAGS) -o $@ $(OBJS)

clean:
	rm -f $(PROGRAM) $(OBJS) parser.c enumMap.txt speed*.txt; \
	rm -rf mac_installer/Package_Root/usr/local/bin mac_installer/Support_Root mac_installer/*.pkg; \
	rm -f mac_installer/Resources/*.html

# Build for windows on a *nix machine with MinGW installed
windows: parser.c
	/usr/bin/i586-mingw32msvc-cc -c -Wall -O3 *.c
	/usr/bin/i586-mingw32msvc-cc *.o -Wl,--dy -o multimarkdown.exe

# Test program against MMD Test Suite
test: $(PROGRAM)
	cd MarkdownTest; \
	./MarkdownTest.pl --Script=../$(PROGRAM) --Tidy --Flags="--compatibility"; \
	echo ""; \
	echo "** It's expected that we fail the \"Ordered and unordered lists\" test **"; \
	echo "";

test-mmd: $(PROGRAM)
	cd MarkdownTest; \
	./MarkdownTest.pl --Script=../$(PROGRAM) --testdir=MultiMarkdownTests

test-compat: $(PROGRAM)
	cd MarkdownTest; \
	./MarkdownTest.pl --Script=../$(PROGRAM) --testdir=CompatibilityTests --Flags="--compatibility"

test-latex: $(PROGRAM)
	cd MarkdownTest; \
	./MarkdownTest.pl --Script=../$(PROGRAM) --testdir=MultiMarkdownTests --Flags="-t latex" --ext=".tex"

test-beamer: $(PROGRAM)
	cd MarkdownTest; \
	./MarkdownTest.pl --Script=../$(PROGRAM) --testdir=BeamerTests --Flags="-t beamer" --ext=".tex"

test-memoir: $(PROGRAM)
	cd MarkdownTest; \
	./MarkdownTest.pl --Script=../$(PROGRAM) --testdir=MemoirTests --Flags="-t memoir" --ext=".tex"

test-opml: $(PROGRAM)
	cd MarkdownTest; \
	./MarkdownTest.pl --Script=../$(PROGRAM) --testdir=MultiMarkdownTests --Flags="-t opml" --ext=".opml"

test-odf: $(PROGRAM)
	cd MarkdownTest; \
	./MarkdownTest.pl --Script=../$(PROGRAM) --testdir=MultiMarkdownTests --Flags="-t odf" --ext=".fodt"

test-xslt: $(PROGRAM)
	cd MarkdownTest; \
	./MarkdownTest.pl --Script=/bin/cat --testdir=MultiMarkdownTests \
	--TrailFlags="| ../Support/bin/mmd2tex-xslt" --ext=".tex"; \
	./MarkdownTest.pl --Script=/bin/cat --testdir=BeamerTests \
	--TrailFlags="| ../Support/bin/mmd2tex-xslt" --ext=".tex"; \
	./MarkdownTest.pl --Script=/bin/cat --testdir=MemoirTests \
	--TrailFlags="| ../Support/bin/mmd2tex-xslt" --ext=".tex"; \

test-all: $(PROGRAM) test test-mmd test-compat test-latex test-beamer test-memoir test-opml test-odf

enumMap.txt: parser.h
	./enumsToPerl.pl libMultiMarkdown.h enumMap.txt

speed.txt: MarkdownTest/Tests/Markdown\ Documentation\ -\ Basics.text
	@ cp MarkdownTest/Tests/Markdown\ Documentation\ -\ Basics.text speed.txt

speed2.txt: speed.txt
	@ cat speed.txt speed.txt > speed2.txt

speed4.txt: speed2.txt
	@ cat speed2.txt speed2.txt > speed4.txt

speed8.txt: speed4.txt
	@ cat speed4.txt speed4.txt > speed8.txt

speed16.txt: speed8.txt
	@ cat speed8.txt speed8.txt > speed16.txt

speed32.txt: speed16.txt
	@ cat speed16.txt speed16.txt > speed32.txt

speed64.txt: speed32.txt
	 @ cat speed32.txt speed32.txt > speed64.txt

speed128.txt: speed64.txt
	@ cat speed64.txt speed64.txt > speed128.txt

speed256.txt: speed128.txt
	@ cat speed128.txt speed128.txt > speed256.txt

speed512.txt: speed256.txt
	@ cat speed256.txt speed256.txt > speed512.txt

# Compare regular with compatibility mode
test-speed: $(PROGRAM) speed512.txt
	time ./$(PROGRAM) speed512.txt > /dev/null
	time ./$(PROGRAM) -c speed512.txt > /dev/null

# Compare with peg-markdown (if installed)
test-speed-jgm: $(PROGRAM) speed512.txt
	time ./$(PROGRAM) speed512.txt > /dev/null
	time ./$(PROGRAM) -c speed512.txt > /dev/null
	time peg-markdown speed512.txt > /dev/null

# Compare with original Markdown.pl
# running tests on Markdown.pl with larger files will take a *long* time
test-speed-gruber: speed64.txt
	time ./$(PROGRAM) -c speed64.txt > /dev/null
	time MarkdownTest/Markdown.pl speed64.txt > /dev/null

# Build Mac Installer
mac-installer: $(PROGRAM)
	mkdir -p mac_installer/Package_Root/usr/local/bin
	mkdir -p mac_installer/Support_Root/Library/Application\ Support
	mkdir -p mac_installer/Resources
	rm -rf mac_installer/Support_Root
	cp multimarkdown scripts/mmd* mac_installer/Package_Root/usr/local/bin/
	./multimarkdown README.md > mac_installer/Resources/README.html
	./multimarkdown mac_installer/Resources/Welcome.txt > mac_installer/Resources/Welcome.html
	./multimarkdown LICENSE > mac_installer/Resources/License.html
	./multimarkdown mac_installer/Resources/Support_Welcome.txt > mac_installer/Resources/Support_Welcome.html
	git clone Support mac_installer/Support_Root/Library/Application\ Support/MultiMarkdown
	cd mac_installer; /Applications/PackageMaker.app/Contents/MacOS/PackageMaker \
	--doc "Make Support Installer.pmdoc" \
	--title "MultiMarkdown Support Files" \
	--version $(VERSION) \
	--filter "\.DS_Store" \
	--filter "\.git" \
	--id net.fletcherpenney.MMD-Support.pkg \
	--domain user \
	--out "MultiMarkdown-Support-Mac-$(VERSION).pkg" \
	--no-relocate; \
	/Applications/PackageMaker.app/Contents/MacOS/PackageMaker \
	--doc "Make OS X Installer.pmdoc" \
	--title "MultiMarkdown" \
	--version $(VERSION) \
	--filter "\.DS_Store" \
	--filter "\.git" \
	--id net.fletcherpenney.multimarkdown.pkg \
	--out "MultiMarkdown-Mac-$(VERSION).pkg"
	cd mac_installer; zip -r MultiMarkdown-Mac-$(VERSION).zip MultiMarkdown-Mac-$(VERSION).pkg
	cd mac_installer; zip -r MultiMarkdown-Support-Mac-$(VERSION).zip MultiMarkdown-Support-Mac-$(VERSION).pkg	

# Prepare README and other files to create the BitRock installer
win-prep: $(PROGRAM)
	mkdir -p windows_installer
	cp multimarkdown.exe windows_installer/
	cp README.md windows_installer/README.txt
	./multimarkdown LICENSE > windows_installer/LICENSE.html

# After creating the installer with BitRock, package it up
win-installer:
	zip -r windows_installer/MultiMarkdown-Windows-$(VERSION).zip windows_installer/MMD-windows-$(VERSION).exe -x windows_installer/MultiMarkdown*.zip
	cd windows_installer; zip -r MultiMarkdown-Windows-Portable-$(VERSION).zip *.bat multimarkdown.exe README.txt LICENSE.html -x install_multimarkdown.bat

