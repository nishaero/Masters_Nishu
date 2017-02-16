# File          : Makefile
# Author(s)     : Daniel Kriesten
# Email         : daniel.kriesten@etit.tu-chemnitz.de
# Creation Date : <Di 18 Nov 2014 16:06:15 krid>
# Last Modified : <Mo 09 Mär 2015 12:45:44 krid>
########################################################################
# Usage: make
########################################################################

# Change to e.g. masterthesis_mustermann
BASENAME=Masters_Nishu

### Pictures that are only available as .pdf
DIRECT_PDF_PICS_IN=

### Directories ###
CURRENT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
TEX_SRC_DIR=./
INC_SRC_DIR=./include
GLOSS_SRC_DIR=./glossaries
SVG_SRC_DIR=./pictures/svg
PDF_SRC_DIR=./pictures/pdf
PNG_SRC_DIR=./pictures/png
BIB_DIR=./bib

### Files ###
WORKFILES=4ct 4tc acn acr alg aux bbl bcf blg glg glo gls glx gxg gxs idv idx ilg ind ist lg lof log lot out run.xml slg syg syi tmp toc xdy xref
TEXFILES=$(shell  find $(TEX_SRC_DIR)   -maxdepth 1 -name '*.tex')
TEXFILES+=$(shell find $(INC_SRC_DIR)   -maxdepth 1 -name '*.tex')  #wird nur benoetigt, wenn maxdepth 1 in find genutzt wird
#TEXFILES+=$(shell find $(INC_SRC_DIR)   -maxdepth 1 -name '*REV*' -prune -o -name '*.tex' -print)  #wird nur benoetigt, wenn maxdepth 1 in find genutzt wird
GLSFILES=$(shell find $(GLOSS_SRC_DIR)  -maxdepth 1 -name '*.tex')  #wird nur benoetigt, wenn maxdepth 1 in find genutzt wird
TEXFILES+=$(GLSFILES)                                               #wird nur benoetigt, wenn maxdepth 1 in find genutzt wird
INCFILES=$(shell  find $(TEX_SRC_DIR)   -maxdepth 1 -name '*.sty')
INCFILES+=$(shell find $(INC_SRC_DIR)   -maxdepth 1 -name '*.sty')  #wird nur benoetigt, wenn maxdepth 1 in find genutzt wird
AUXFILES=$(shell  find .                -name '*.aux')
BIBFILES=$(shell  find $(BIB_DIR)       -maxdepth 1 -name '*.bib')
SVGFILES=$(shell  find $(SVG_SRC_DIR)   -maxdepth 1 -name '*.svg' -and -not -name '._*' -print)
PNG_PICS=$(shell  find $(PNG_SRC_DIR)   -maxdepth 1 -name '*.png' -and -not -name '._*' -print)
PDF_PICS=$(addprefix $(PDF_SRC_DIR)/,$(PDF_PICS_IN))
SVG_PICS=$(addprefix $(PDF_SRC_DIR)/,$(addsuffix .pdf, $(basename $(notdir $(SVGFILES)))))

### git stuff ###
GITREVISION=$(shell git describe --always --tags HEAD 2>/dev/null || echo "No Git-Revision")

### Number of rounds ###
LATEX_COUNT=6

### global targets ###
all: pdf

pdf: $(BASENAME).pdf

pics: $(PDF_PICS) $(SVG_PICS) $(PNG_PICS)
	@echo "all pictures should be uptodate"

gloss: $(AUXFILES) $(GLSFILES)
	@makeglossaries $(BASENAME)
	#@makeglossaries -L german -g $(BASENAME)

bbl: $(BASENAME).bbl

copy: $(BASENAME).pdf
	@mkdir -vp $(CURRENT_DIR)/_result/$(BASENAME)/
	@cp -v $<  $(CURRENT_DIR)/_result/$(BASENAME)/$(BASENAME).pdf
	@rm -vf    $(CURRENT_DIR)/_result/$(BASENAME)/$(BASENAME)-v20*
	@touch     $(CURRENT_DIR)/_result/$(BASENAME)/$(BASENAME)-$(GITREVISION)

### tools ###
PDF_TOOL=pdflatex -interaction=nonstopmode -halt-on-error -file-line-error -synctex=1
INKSCAPE=$(shell which inkscape || echo "/Applications/Inkscape.app/Contents/Resources/bin/inkscape")
RM=rm -vf

### work targets ###
$(BASENAME).pdf: $(TEXFILES) $(INCFILES) $(BIBFILES) $(PDF_PICS) $(SVG_PICS) $(PNG_PICS)
	@echo "Adding Versiontag: $(GITREVISION)"
	@sed -e "s/\({-- Entwurf\).*\(--}\)/\1 $(GITREVISION) \2/" $(INC_SRC_DIR)/metadaten.sty > $(INC_SRC_DIR)/metadatenREV.sty
	@echo "Running $(PDF_TOOL) ..."
	@$(PDF_TOOL) $(TEX_SRC_DIR)/$(BASENAME).tex >& /dev/null
	@egrep 'run Biber' ${BASENAME}.log  >& /dev/null && $(MAKE) bbl || true
	#$(MAKE) bbl
	$(MAKE) gloss
	@latex_count=${LATEX_COUNT} ; \
	while egrep -s 'Rerun (LaTeX|to get (outlines|cross-references) right)' ${BASENAME}.log || egrep -s 'run Biber' ${BASENAME}.log && [ $$latex_count -gt 0 ] ;\
	do \
	  if egrep -s 'run Biber' ${BASENAME}.log; then \
	    biber $(BASENAME); \
	  fi; \
		echo "Rerunning $(PDF_TOOL)...." ;\
		$(PDF_TOOL) $(TEX_SRC_DIR)/$(BASENAME).tex >& /dev/null ;\
		latex_count=`expr $$latex_count - 1` ;\
	done; echo "\o/\n $$latex_count \n/ \ "

$(BASENAME).bbl: $(BASENAME).bcf $(BIBFILES)
	@echo "Running bibtex for $< ..."
	@biber $(BASENAME)

#helping hook - the bcf file is created automatically by the first pdflatex run
$(BASENAME).bcf: $(BASENAME).pdf

$(PDF_SRC_DIR)/%.pdf: $(SVG_SRC_DIR)/%.svg
	@echo "Creating $@ from svg"
	$(INKSCAPE) --without-gui --export-area-page --file=$(CURRENT_DIR)/$< --export-pdf=$(CURRENT_DIR)/$@

### clean stages ###
.PHONY: clean distclean resultclean show showlog

showlog:
	@cat $(BASENAME).log

show:
	open -a skim $(BASENAME).pdf

clean:
	@$(RM) $(addprefix $(BASENAME).,$(WORKFILES))
	@$(RM) $(addprefix *.,$(WORKFILES))
	@$(RM) $(addprefix */*.,$(WORKFILES))
	@$(RM) */*.bak

picsclean:
	@echo "git clean -fdx"
	@git clean -ndx $(SVG_SRC_DIR)
	@git clean -ndx $(PDF_SRC_DIR)
	@git clean -ndx $(PNG_SRC_DIR)

resultclean:
	@$(RM) $(BASENAME).synctex.gz
	@$(RM) $(BASENAME).pdf

distclean: clean resultclean
	@echo "Should do git clean -fdx"
	@git clean --exclude '.*.swp' --exclude '*.tex' -ndx

########################################################################
# vim: ts=2:sw=2:tw=80:fileformat=unix:noexpandtab
