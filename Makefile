all: pixitie

RESOURCES = ascii.cs \
  epson-fx80.cs epson-fx80-variants.pxfi EpsonFX80.pxf \
  EpsonFX80-Italic.pxf \
  bradford.cs \
  Bradford-1-Monospaced.pxf Bradford-2-Monospaced.pxf \
  Bradford-3-Monospaced.pxf Bradford-4-Monospaced.pxf \
  Bradford-5-Monospaced.pxf Bradford-6-Monospaced.pxf \
  Bradford-7-Monospaced.pxf Bradford-8-Monospaced.pxf \
  Bradford-Kazmiruk-T-Monospaced.pxf \
  Bradford-Kazmiruk-O-Monospaced.pxf \
  Bradford-Kazmiruk-M-Monospaced.pxf \
  Bradford-Greek-Monospaced.pxf Bradford-Greek-Monospaced.cs \
  Bradford-Extra-9-Monospaced.pxf \
  Bradford-Extra-A-Monospaced.pxf \
  Bradford-Extra-B-Monospaced.pxf \
  Bradford-Extra-C-Monospaced.pxf \
  Bradford-Extra-F-Monospaced.pxf \
  Bradford-Extra-J-Monospaced.pxf \
  Bradford-Extra-K-Monospaced.pxf \
  Bradford-Extra-L-Monospaced.pxf \
  Bradford-Extra-M-Monospaced.pxf \
  Bradford-Extra-N-Monospaced.pxf \
  Bradford-Extra-O-Monospaced.pxf \
  Bradford-Extra-P-Monospaced.pxf \
  Bradford-Extra-S-Monospaced.pxf \
  Bradford-Extra-T-Monospaced.pxf \
  ZXSpectrum-Chargen.pxf zx-spectrum.cs ZXSpectrum-Chargen.8x8.hex \
  NLQ401.cs NLQ401.pxf \
  NLQ401-Draft.cs NLQ401-Draft.pxf \
  NLQ401-Draft-Extra.cs NLQ401-Draft-Extra.pxf \
  DMP2000.pxf \
  DMP3000-NLQ.pxf DMP3000-NLQ-Italic.pxf DMP3000-NLQ-Extra.pxf DMP3000-Draft-Extra.pxf dmp3000-extra.cs \
  DMP3160-NLQ.pxf DMP3160-NLQ-Italic.pxf \
  DMP3160-Draft.pxf DMP3160-Draft-Italic.pxf \
  7seg.cs \
  7seg-Boxy-Draft.pxf 7seg-Boxy-Narrowed-Draft.pxf \
  7seg-Boxy-NLQ.pxf 7seg-Boxy-NLQ-Rounded.pxf 7seg-Boxy-Narrowed-NLQ.pxf 7seg-Boxy-Narrowed-NLQ-Rounded.pxf \
  7seg-Mini-Draft.pxf \
  abridged-unicode.txt \
  old-hylian.cs \
  Old-Hylian-Draft.pxf Old-Hylian-NLQ.pxf Old-Hylian-NLQ-Elite.pxf Old-Hylian-NLQ-Dense.pxf \
  braille.cs \
  Braille-Draft.pxf \
  taiogeuna.cs \
  Taiogeuna-Draft.pxf Taiogeuna-NLQ.pxf \
  latin1.cs \
  Gohufont-11.pxf Gohufont-11-Bold.pxf Gohufont-14.pxf Gohufont-14-Bold.pxf \
  Gohufont-Uni-11.cs Gohufont-Uni-14.cs \
  Gohufont-Uni-11.pxf Gohufont-Uni-11-Bold.pxf Gohufont-Uni-14.pxf Gohufont-Uni-14-Bold.pxf \
  Default8x16.cs Default8x16.pxf \
  monobook.cs \
  Monobook-12.pxf Monobook-16.pxf Monobook-20.pxf Monobook-24.pxf Monobook-28.pxf \
  Monobook-16-Bold.pxf Monobook-20-Bold.pxf Monobook-24-Bold.pxf Monobook-28-Bold.pxf \
  inputs/glyphlist.txt

pixitie: pixitie-code.rb $(RESOURCES)
	( \
          cat pixitie-code.rb; \
          for f in $(RESOURCES); \
          do \
            echo; \
            echo "/$$(basename "$$f")/"; \
            cat "$$f"; \
          done \
        ) > $@
	chmod +x $@

ZXSpectrum-Chargen.8x8.hex: ZXSpectrum-Chargen.8x8 i8hex-encode.rb
	./i8hex-encode.rb < $< > $@

clean:
	rm -vf Bradford-?-Monospaced.pxf
	rm -vf ZXSpectrum-Chargen.8x8.hex
	rm -vf NLQ401.pxf
	rm -vf NLQ401-Draft.pxf
	rm -vf NLQ401-Draft-Extra.pxf
	rm -vf DMP2000.pxf
	rm -vf DMP3000-NLQ.pxf
	rm -vf DMP3000-NLQ-Italic.pxf
	rm -vf DMP3000-NLQ-Extra.pxf
	rm -vf DMP3000-Draft-Extra.pxf
	rm -vf DMP3160-NLQ.pxf
	rm -vf DMP3160-NLQ-Italic.pxf
	rm -vf DMP3160-Draft.pxf
	rm -vf DMP3160-Draft-Italic.pxf

# Bradford fonts
bradford.arc:
	wget 'http://www.zimmers.net/anonftp/pub/cpm/printer/bradford.arc'

Bradford-1.brad: origname := FONT1.BIN
Bradford-2.brad: origname := FONT2.BIN
Bradford-3.brad: origname := FONT3.BIN
Bradford-4.brad: origname := FONT4.BIN
Bradford-5.brad: origname := FONT5.BIN
Bradford-6.brad: origname := FONT6.BIN
Bradford-7.brad: origname := FONT7.BIN
Bradford-8.brad: origname := FONT8.BIN

Bradford-1.brad: bradford.arc
	arc p $< ${origname} > $@

Bradford-2.brad: bradford.arc
	arc p $< ${origname} > $@

Bradford-3.brad: bradford.arc
	arc p $< ${origname} > $@

Bradford-4.brad: bradford.arc
	arc p $< ${origname} > $@

Bradford-5.brad: bradford.arc
	arc p $< ${origname} > $@

Bradford-6.brad: bradford.arc
	arc p $< ${origname} > $@

Bradford-7.brad: bradford.arc
	arc p $< ${origname} > $@

Bradford-8.brad: bradford.arc
	arc p $< ${origname} > $@

Bradford-1-Monospaced.pxf: options := -b2
Bradford-2-Monospaced.pxf: options := -b2
Bradford-3-Monospaced.pxf: options := -b2
Bradford-4-Monospaced.pxf: options := -b3
Bradford-5-Monospaced.pxf: options := -b3
Bradford-6-Monospaced.pxf: options := -b2
Bradford-7-Monospaced.pxf: options := -b2
Bradford-8-Monospaced.pxf: options := -b2

# NLQ401 fonts

NLQ401_Charset.png:
	wget 'http://www.cpcwiki.eu/imgs/a/a1/NLQ401_Charset.png'

NLQ401.pxf: NLQ401_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=12,15 \
          --skew=8 \
          --range=0x18..0x7E \
          --pad-bottom=2 \
          --pixel-step=1,3 \
          --cell-size=39,18 \
          --pad-right=1 \
          --check-horizontal-neighbours \
          --cell-step=55,65 \
          -h 'charset NLQ401.cs' \
          -h '' \
          -h 'aspect-ratio 18:25' \
          -h 'horizontal-compression 1/4' \
          -h 'vertical-compression 1/2' \
          -h 'circular-dots' \
          -h 'baseline 7' \
          $< > $@

NLQ401-Draft.pxf: NLQ401_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=12,530 \
          --skew=8 \
          --range=0x18..0xFF \
          --pad-bottom=3 \
          --pixel-step=4,3 \
          --cell-size=11,18 \
          --pad-right=1 \
          --vsparse \
          --check-horizontal-neighbours \
          --cell-step=55,65 \
          -h 'charset NLQ401-Draft.cs' \
          -h '' \
          -h 'aspect-ratio 6:5' \
          -h 'horizontal-compression 1/2' \
          -h 'circular-dots' \
          -h 'baseline 5' \
          $< > $@

NLQ401-Draft-Extra.pxf: NLQ401_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=12,985 \
          --range=0x80..0xFF \
          --pad-bottom=3 \
          --pixel-step=4,3 \
          --cell-size=12,18 \
          --vsparse \
          --check-horizontal-neighbours \
          --hsparse \
          --cell-step=55,65 \
          -h 'charset NLQ401-Draft-Extra.cs' \
          -h '' \
          -h 'aspect-ratio 6:5' \
          -h 'circular-dots' \
          -h 'baseline 5' \
          $< > $@

# DMP2000 font
DMP2000_Charset.png:
	wget 'http://www.cpcwiki.eu/imgs/f/f3/DMP2000_Charset.png'

DMP2000.pxf: DMP2000_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=12,17 \
          --range=0x00..0x7F \
          --pad-bottom=2 \
          --pixel-step=4,3 \
          --cell-size=11,18 \
          --pad-right=1 \
          --cell-step=55,65 \
          -h 'charset epson-fx80.cs' \
          -h '' \
          -h 'aspect-ratio 6:5' \
          -h 'horizontal-compression 1/2' \
          -h 'vertical-compression 1/2' \
          -h 'circular-dots' \
          -h 'baseline 7' \
          -h '' \
          -h 'variant-bit Underscored /columns |4' \
          $< > $@

# DMP3000 fonts
DMP3000_Charset.png:
	wget 'http://www.cpcwiki.eu/imgs/8/80/DMP3000_Charset.png'

DMP3000-NLQ.pxf: DMP3000_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=12,17 \
          --range=0x00..0x7F \
          --pad-bottom=2 \
          --pixel-step=4,3 \
          --cell-size=11,18 \
          --pad-right=1 \
          --cell-step=55,65 \
          -h 'charset epson-fx80.cs' \
          -h '' \
          -h 'aspect-ratio 6:5' \
          -h 'horizontal-compression 1/2' \
          -h 'vertical-compression 1/2' \
          -h 'circular-dots' \
          -h 'baseline 7' \
          -h '' \
          -h 'variant-bit Underscored /columns |4' \
          $< > $@

DMP3000-NLQ-Italic.pxf: DMP3000_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=12,537 \
          --range=0x00..0x7F \
          --pad-bottom=2 \
          --pixel-step=4,3 \
          --cell-size=11,18 \
          --pad-right=1 \
          --cell-step=55,65 \
          -h 'charset epson-fx80.cs' \
          -h '' \
          -h 'aspect-ratio 6:5' \
          -h 'horizontal-compression 1/2' \
          -h 'vertical-compression 1/2' \
          -h 'circular-dots' \
          -h 'baseline 7' \
          -h '' \
          -h 'variant-bit Underscored /columns |4' \
          $< > $@

DMP3000-NLQ-Extra.pxf: DMP3000_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=12,1057 \
          --range=0x00..0x4B \
          --pad-bottom=2 \
          --pixel-step=4,3 \
          --cell-size=11,18 \
          --pad-right=1 \
          --cell-step=55,65 \
          -h 'charset dmp3000-extra.cs' \
          -h '' \
          -h 'aspect-ratio 6:5' \
          -h 'horizontal-compression 1/2' \
          -h 'vertical-compression 1/2' \
          -h 'circular-dots' \
          -h 'baseline 7' \
          $< > $@

DMP3000-Draft-Extra.pxf: DMP3000_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=12,1442 \
          --range=0x00..0x6C \
          --pad-bottom=3 \
          --pixel-step=4,3 \
          --cell-size=11,18 \
          --vsparse \
          --pad-right=1 \
          --cell-step=55,65 \
          -h 'charset dmp3000-extra.cs' \
          -h '' \
          -h 'aspect-ratio 6:5' \
          -h 'horizontal-compression 1/2' \
          -h 'circular-dots' \
          -h 'baseline 5' \
          $< > $@

# DMP3160 fonts
DMP3160_Charset.png:
	wget 'http://www.cpcwiki.eu/imgs/a/a6/DMP3160_Charset.png'

DMP3160-NLQ.pxf: DMP3160_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=12,17 \
          --range=0x00..0x7F \
          --pad-bottom=2 \
          --pixel-step=4,3 \
          --cell-size=11,18 \
          --pad-right=1 \
          --cell-step=55,65 \
          -h 'charset epson-fx80.cs' \
          -h '' \
          -h 'aspect-ratio 6:5' \
          -h 'horizontal-compression 1/2' \
          -h 'vertical-compression 1/2' \
          -h 'circular-dots' \
          -h 'baseline 7' \
          -h '' \
          -h 'variant-bit Underscored /columns |4' \
          $< > $@

DMP3160-NLQ-Italic.pxf: DMP3160_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=12,537 \
          --range=0x00..0x7F \
          --pad-bottom=2 \
          --pixel-step=4,3 \
          --cell-size=11,18 \
          --pad-right=1 \
          --cell-step=55,65 \
          -h 'charset epson-fx80.cs' \
          -h '' \
          -h 'aspect-ratio 6:5' \
          -h 'horizontal-compression 1/2' \
          -h 'vertical-compression 1/2' \
          -h 'circular-dots' \
          -h 'baseline 7' \
          -h '' \
          -h 'variant-bit Underscored /columns |4' \
          $< > $@

DMP3160-Draft.pxf: DMP3160_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=912,17 \
          --range=0x00..0x7F \
          --pad-bottom=3 \
          --pixel-step=4,3 \
          --cell-size=11,18 \
          --vsparse \
          --pad-right=1 \
          --cell-step=55,65 \
          -h 'charset epson-fx80.cs' \
          -h '' \
          -h 'aspect-ratio 6:5' \
          -h 'horizontal-compression 1/2' \
          -h 'circular-dots' \
          -h 'baseline 5' \
          -h '' \
          -h 'variant-bit Underscored /columns |8 : &~8' \
          $< > $@

DMP3160-Draft-Italic.pxf: DMP3160_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=912,537 \
          --range=0x00..0x7F \
          --pad-bottom=3 \
          --pixel-step=4,3 \
          --cell-size=11,18 \
          --vsparse \
          --pad-right=1 \
          --cell-step=55,65 \
          -h 'charset epson-fx80.cs' \
          -h '' \
          -h 'aspect-ratio 6:5' \
          -h 'horizontal-compression 1/2' \
          -h 'circular-dots' \
          -h 'baseline 5' \
          -h '' \
          -h 'variant-bit Underscored /columns |8 : &~8' \
          $< > $@

# Modified Bradford fonts by Stan Kazmiruk

inputs/BRFONTS.LBR:
	wget 'http://www.retroarchive.org/cpm/cdrom/CPM/PROGRAMS/LIST/BRFONTS.LBR' -O $@

Bradford-Kazmiruk-T.brad: origname = fontt.bin
Bradford-Kazmiruk-O.brad: origname = fonto.bin
Bradford-Kazmiruk-M.brad: origname = fontm.bin

Bradford-Kazmiruk-T-Monospaced.pxf: options := -b2
Bradford-Kazmiruk-O-Monospaced.pxf: options := -b0
Bradford-Kazmiruk-M-Monospaced.pxf: options := -b2

Bradford-Kazmiruk-T.brad: inputs/BRFONTS.LBR
	lar p $< ${origname} > $@

Bradford-Kazmiruk-O.brad: inputs/BRFONTS.LBR
	lar p $< ${origname} > $@

Bradford-Kazmiruk-M.brad: inputs/BRFONTS.LBR
	lar p $< ${origname} > $@

# A Greek Bradford font by Calvin T. Richter

inputs/BRAD-GRK.LBR:
	wget 'http://www.retroarchive.org/cpm/cdrom/CPM/PROGRAMS/LIST/BRAD-GRK.LBR' -O $@

Bradford-Greek.brad: origname = font@.bin

Bradford-Greek-Monospaced.pxf: options := -b2 -cBradford-Greek-Monospaced.cs

Bradford-Greek.brad: inputs/BRAD-GRK.LBR
	lar p $< ${origname} > $@

# Bradford extra fonts, by Aaron Contorer and Fredric N. Loring
EXTRAFON.LBR:
	wget 'http://www.retroarchive.org/cpm/cdrom/CPM/PROGRAMS/LIST/EXTRAFON.LBR'

Bradford-Extra-9-Monospaced.pxf: options := -b0
Bradford-Extra-A-Monospaced.pxf: options := -b2 -cascii.cs
Bradford-Extra-B-Monospaced.pxf: options := -b2
Bradford-Extra-C-Monospaced.pxf: options := -b2
Bradford-Extra-F-Monospaced.pxf: options := -b2
Bradford-Extra-J-Monospaced.pxf: options := -b2
Bradford-Extra-K-Monospaced.pxf: options := -b2
Bradford-Extra-L-Monospaced.pxf: options := -b2
Bradford-Extra-M-Monospaced.pxf: options := -b2
Bradford-Extra-N-Monospaced.pxf: options := -b2
Bradford-Extra-O-Monospaced.pxf: options := -b2
Bradford-Extra-P-Monospaced.pxf: options := -b2
Bradford-Extra-S-Monospaced.pxf: options := -b2
Bradford-Extra-T-Monospaced.pxf: options := -b2

Bradford-Extra-9.brad: EXTRAFON.LBR
	lar p $< font9.bzn | uncrunch /dev/stdin
	mv -vf font9.bin $@

Bradford-Extra-A.brad: EXTRAFON.LBR
	lar p $< fonta.bzn | uncrunch /dev/stdin
	mv -vf fonta.bin $@

Bradford-Extra-B.brad: EXTRAFON.LBR
	lar p $< fontb.bzn | uncrunch /dev/stdin
	mv -vf fontb.bin $@

Bradford-Extra-C.brad: EXTRAFON.LBR
	lar p $< fontc.bzn | uncrunch /dev/stdin
	mv -vf fontc.bin $@

Bradford-Extra-F.brad: EXTRAFON.LBR
	lar p $< fontf.bzn | uncrunch /dev/stdin
	mv -vf fontf.bin $@

Bradford-Extra-J.brad: EXTRAFON.LBR
	lar p $< fontj.bzn | uncrunch /dev/stdin
	mv -vf fontj.bin $@

Bradford-Extra-K.brad: EXTRAFON.LBR
	lar p $< fontk.bzn | uncrunch /dev/stdin
	mv -vf fontk.bin $@

Bradford-Extra-L.brad: EXTRAFON.LBR
	lar p $< fontl.bzn | uncrunch /dev/stdin
	mv -vf fontl.bin $@

Bradford-Extra-M.brad: EXTRAFON.LBR
	lar p $< fontm.bzn | uncrunch /dev/stdin
	mv -vf fontm.bin $@

Bradford-Extra-N.brad: EXTRAFON.LBR
	lar p $< fontn.bzn | uncrunch /dev/stdin
	mv -vf fontn.bin $@

Bradford-Extra-O.brad: EXTRAFON.LBR
	lar p $< fonto.bzn | uncrunch /dev/stdin
	mv -vf fonto.bin $@

Bradford-Extra-P.brad: EXTRAFON.LBR
	lar p $< fontp.bzn | uncrunch /dev/stdin
	mv -vf fontp.bin $@

Bradford-Extra-S.brad: EXTRAFON.LBR
	lar p $< fonts.bzn | uncrunch /dev/stdin
	mv -vf fonts.bin $@

Bradford-Extra-T.brad: EXTRAFON.LBR
	lar p $< fontt.bzn | uncrunch /dev/stdin
	mv -vf fontt.bin $@

# General Bradford font parsing rule

%-Monospaced.pxf: %.brad bradford2pxf.rb
	./bradford2pxf.rb ${options} < $< > $@

# General Glyph Compositor invocation rule
%.pxf: %.pxf.cg compose-glyphs.pl
	./compose-glyphs.pl $< > $@

# Special dependencies for the Glyph Compositor sources
7seg-Boxy-Draft.pxf 7seg-Boxy-Narrowed-Draft.pxf \
    7seg-Boxy-NLQ.pxf 7seg-Boxy-NLQ-Rounded.pxf 7seg-Boxy-Narrowed-NLQ.pxf 7seg-Boxy-Narrowed-NLQ-Rounded.pxf \
    7seg-Mini-Draft.pxf: 7seg-compositions.cg

# Braille font generation rule
Braille-Draft.pxf.cg: generate-Braille-Draft.pxf.cg.pl
	./generate-Braille-Draft.pxf.cg.pl > $@

# Monobook conversion rules
Monobook-12.pxf: inputs/monobook-font-0.22/mb12m.bdf
	./bdf2pxf.pl -c monobook.cs $< > $@

Monobook-16.pxf: inputs/monobook-font-0.22/mb16m.bdf
	./bdf2pxf.pl -c monobook.cs $< > $@

Monobook-20.pxf: inputs/monobook-font-0.22/mb20m.bdf
	./bdf2pxf.pl -c monobook.cs $< > $@

Monobook-24.pxf: inputs/monobook-font-0.22/mb24m.bdf
	./bdf2pxf.pl -c monobook.cs $< > $@

Monobook-28.pxf: inputs/monobook-font-0.22/mb28m.bdf
	./bdf2pxf.pl -c monobook.cs $< > $@

Monobook-16-Bold.pxf: inputs/monobook-font-0.22/mb16b.bdf
	./bdf2pxf.pl -c monobook.cs $< > $@

Monobook-20-Bold.pxf: inputs/monobook-font-0.22/mb20b.bdf
	./bdf2pxf.pl -c monobook.cs $< > $@

Monobook-24-Bold.pxf: inputs/monobook-font-0.22/mb24b.bdf
	./bdf2pxf.pl -c monobook.cs $< > $@

Monobook-28-Bold.pxf: inputs/monobook-font-0.22/mb28b.bdf
	./bdf2pxf.pl -c monobook.cs $< > $@

# console-fonts/ extraction rules

Default8x16.pxf Default8x16.cs: inputs/consolefonts/default8x16.psf.gz
	./psf2pxf.rb $< --output-charset Default8x16.cs \
        -h 'variant-bit Printerified aspect-ratio 6:5, horizontal-compression 1/2, circular-dots, /pad 1' \
        > Default8x16.pxf

#### Download rules

inputs/glyphlist.txt:
	wget 'http://partners.adobe.com/public/developer/en/opentype/glyphlist.txt' -O $@

#### Overview generation rules

overviews: overviews/Old-Hylian-Draft.pdf
.PHONY: overviews

overviews/Old-Hylian-Draft.ps: Old-Hylian-Draft.pxf old-hylian.cs
        # We'll pass -R. to Pixitie even though it already has the font.  This
        # is to ensure that it uses the external, not the embedded version of
        # relevant resources.  (Recall that external resources take precedence
        # over internal ones.)
	./pixitie -R. --showcase Old-Hylian-Draft > $@

overviews/Old-Hylian-Draft.pdf: overviews/Old-Hylian-Draft.ps
        # Apple's pstopdf is often, but not always, able to perform the
        # conversion.  It particularly seems to have trouble with fonts larger
        # than 255 (sic) glyphs.
        #
        # We'll rely on GhostScript's ps2pdf, which is more reliable.
	ps2pdf $< $@
