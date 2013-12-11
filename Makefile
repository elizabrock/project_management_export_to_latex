JUNK_FILES= *.aux *.log styles/*.aux *.dvi

TEX	:= buildout_plan_for_igodigital_guided_selling_light_20120810_1819.tex
DVI	= $(TEX:%.tex=%.dvi)
PDF	= $(TEX:%.tex=%.pdf)

release: clean view

view: $(PDF)
	open $(PDF)

$(PDF):
	pdflatex -halt-on-error $(TEX)
	pdflatex -halt-on-error $(TEX)

clean:
	rm -rf $(JUNK_FILES)
	-rm -f *.log *.aux *.dvi *.bbl *.blg *.ilg *.toc *.lof *.lot *.idx *.ind *.ps  *~
	find . -name "*.aux" -exec rm {} \;
