all: pixitie

RESOURCES = ascii.cs \
  epson-fx80.cs epson-fx80-variants.pxfi \
  bradford.cs \
  Bradford-Greek.cs \
  zx-spectrum.cs ZXSpectrum-Chargen.8x8.hex \
  Atari-Graphic.cs \
  dmp3000-extra.cs \
  NLQ401.cs NLQ401-Draft.cs NLQ401-Draft-Extra.cs \
  7seg.cs 14seg.cs Russian-Postcode.cs \
  abridged-unicode.txt \
  old-hylian.cs \
  braille.cs \
  taiogeuna.cs \
  latin1.cs \
  Gohufont-Uni-11.cs Gohufont-Uni-14.cs \
  Default8x9.cs Default8x16.cs Lat1-08.cs \
  Goha-12.cs Goha-14.cs Goha-16.cs \
  GohaClassic-12.cs GohaClassic-14.cs GohaClassic-16.cs \
  monobook.cs \
  $(foreach font, $(OVERVIEWED_FONTS), $(font).pxf) \
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

%.hex: % i8hex-encode.rb
	./i8hex-encode.rb < $< > $@

clean:
	rm -vf Bradford-*.pxf
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

Bradford-1.pxf: options := -b2
Bradford-2.pxf: options := -b2
Bradford-3.pxf: options := -b2
Bradford-4.pxf: options := -b3
Bradford-5.pxf: options := -b3
Bradford-6.pxf: options := -b2
Bradford-7.pxf: options := -b2
Bradford-8.pxf: options := -b2

# NLQ401 fonts

inputs/NLQ401_Charset.png:
	wget 'http://www.cpcwiki.eu/imgs/a/a1/NLQ401_Charset.png' -O $@

NLQ401.pxf: inputs/NLQ401_Charset.png picture2pxf.rb
	./picture2pxf.rb \
          --origin=12,15 \
          --skew=8 \
          --range=0x18..0x7E \
          --pad-bottom=2 \
          --pixel-step=1,3 \
          --cell-size=39,18 \
          --pad-right=9 \
          --check-horizontal-neighbours \
          --cell-step=55,65 \
          -h 'charset NLQ401.cs' \
          -h '' \
          -h 'aspect-ratio 6:5' \
          -h 'horizontal-compression 1/8' \
          -h 'vertical-compression 1/2' \
          -h 'circular-dots' \
          -h 'baseline 7' \
          $< > $@

NLQ401-Draft.pxf: inputs/NLQ401_Charset.png picture2pxf.rb
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

NLQ401-Draft-Extra.pxf: inputs/NLQ401_Charset.png picture2pxf.rb
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
inputs/DMP2000_Charset.png:
	wget 'http://www.cpcwiki.eu/imgs/f/f3/DMP2000_Charset.png' -O $@

DMP2000.pxf: inputs/DMP2000_Charset.png picture2pxf.rb
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
inputs/DMP3000_Charset.png:
	wget 'http://www.cpcwiki.eu/imgs/8/80/DMP3000_Charset.png' -O $@

DMP3000-NLQ.pxf: inputs/DMP3000_Charset.png picture2pxf.rb
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

DMP3000-NLQ-Italic.pxf: inputs/DMP3000_Charset.png picture2pxf.rb
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

DMP3000-NLQ-Extra.pxf: inputs/DMP3000_Charset.png picture2pxf.rb
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

DMP3000-Draft-Extra.pxf: inputs/DMP3000_Charset.png picture2pxf.rb
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
inputs/DMP3160_Charset.png:
	wget 'http://www.cpcwiki.eu/imgs/a/a6/DMP3160_Charset.png' -O $@

DMP3160-NLQ.pxf: inputs/DMP3160_Charset.png picture2pxf.rb
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

DMP3160-NLQ-Italic.pxf: inputs/DMP3160_Charset.png picture2pxf.rb
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

DMP3160-Draft.pxf: inputs/DMP3160_Charset.png picture2pxf.rb
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

DMP3160-Draft-Italic.pxf: inputs/DMP3160_Charset.png picture2pxf.rb
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

Bradford-Kazmiruk-T.pxf: options := -b2
Bradford-Kazmiruk-O.pxf: options := -b0
Bradford-Kazmiruk-M.pxf: options := -b2

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

Bradford-Greek.pxf: options := -b2 -cBradford-Greek.cs

Bradford-Greek.brad: inputs/BRAD-GRK.LBR
	lar p $< ${origname} > $@

# Bradford extra fonts, by Aaron Contorer and Fredric N. Loring
EXTRAFON.LBR:
	wget 'http://www.retroarchive.org/cpm/cdrom/CPM/PROGRAMS/LIST/EXTRAFON.LBR'

Bradford-Extra-9.pxf: options := -b0
Bradford-Extra-A.pxf: options := -b2 -cascii.cs
Bradford-Extra-B.pxf: options := -b2
Bradford-Extra-C.pxf: options := -b2
Bradford-Extra-F.pxf: options := -b2
Bradford-Extra-J.pxf: options := -b2
Bradford-Extra-K.pxf: options := -b2
Bradford-Extra-L.pxf: options := -b2
Bradford-Extra-M.pxf: options := -b2
Bradford-Extra-N.pxf: options := -b2
Bradford-Extra-O.pxf: options := -b2
Bradford-Extra-P.pxf: options := -b2
Bradford-Extra-S.pxf: options := -b2
Bradford-Extra-T.pxf: options := -b2

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

Bradford-%.pxf: Bradford-%.brad bradford2pxf.rb
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

Default8x16.pxf Default8x16.cs: inputs/consolefonts/default8x16.psf.gz psf2pxf.rb
	./psf2pxf.rb $< --output-charset Default8x16.cs \
        -h 'variant-bit Printerified aspect-ratio 6:5, horizontal-compression 1/2, circular-dots, /pad 1' \
        > Default8x16.pxf

Default8x9.pxf Default8x9.cs: inputs/consolefonts/default8x9.psf.gz psf2pxf.rb
	./psf2pxf.rb $< --output-charset Default8x9.cs \
        -h 'variant-bit Printerified aspect-ratio 6:5, horizontal-compression 1/2, circular-dots, /pad 1' \
        > Default8x9.pxf

Lat1-08.pxf Lat1-08.cs: inputs/consolefonts/lat1-08.psf.gz psf2pxf.rb
	./psf2pxf.rb $< --output-charset Lat1-08.cs \
        -h 'variant-bit Printerified aspect-ratio 6:5, horizontal-compression 1/2, circular-dots, /pad 1' \
        > Lat1-08.pxf

# FIXME: the Unicode mapping data from Goha* and GohaClassic* PSFs is full of
# crap and needs to be fixed.

Goha-12.pxf Goha-12.cs: inputs/consolefonts/Goha-12.psf.gz psf2pxf.rb
	./psf2pxf.rb $< --output-charset Goha-12.cs \
        -h 'variant-bit Printerified aspect-ratio 6:5, horizontal-compression 1/2, circular-dots, /pad 1' \
        > Goha-12.pxf

Goha-14.pxf Goha-14.cs: inputs/consolefonts/Goha-14.psf.gz psf2pxf.rb
	./psf2pxf.rb $< --output-charset Goha-14.cs \
        -h 'variant-bit Printerified aspect-ratio 6:5, horizontal-compression 1/2, circular-dots, /pad 1' \
        > Goha-14.pxf

Goha-16.pxf Goha-16.cs: inputs/consolefonts/Goha-16.psf.gz psf2pxf.rb
	./psf2pxf.rb $< --output-charset Goha-16.cs \
        -h 'variant-bit Printerified aspect-ratio 6:5, horizontal-compression 1/2, circular-dots, /pad 1' \
        > Goha-16.pxf

GohaClassic-12.pxf GohaClassic-12.cs: inputs/consolefonts/GohaClassic-12.psf.gz psf2pxf.rb
	./psf2pxf.rb $< --output-charset GohaClassic-12.cs \
        -h 'variant-bit Printerified aspect-ratio 6:5, horizontal-compression 1/2, circular-dots, /pad 1' \
        > GohaClassic-12.pxf

GohaClassic-14.pxf GohaClassic-14.cs: inputs/consolefonts/GohaClassic-14.psf.gz psf2pxf.rb
	./psf2pxf.rb $< --output-charset GohaClassic-14.cs \
        -h 'variant-bit Printerified aspect-ratio 6:5, horizontal-compression 1/2, circular-dots, /pad 1' \
        > GohaClassic-14.pxf

GohaClassic-16.pxf GohaClassic-16.cs: inputs/consolefonts/GohaClassic-16.psf.gz psf2pxf.rb
	./psf2pxf.rb $< --output-charset GohaClassic-16.cs \
        -h 'variant-bit Printerified aspect-ratio 6:5, horizontal-compression 1/2, circular-dots, /pad 1' \
        > GohaClassic-16.pxf

#### Download rules

inputs/glyphlist.txt:
	wget 'http://partners.adobe.com/public/developer/en/opentype/glyphlist.txt' -O $@

#### Overview generation rules

# TODO: OVERVIEWED_FONTS should eventually list all included fonts, and then be renamed accordingly
OVERVIEWED_FONTS = \
    EpsonFX80 EpsonFX80-Italic \
    \
    Bradford-1 Bradford-2 Bradford-3 Bradford-4 Bradford-5 \
    Bradford-6 Bradford-7 Bradford-8 \
    \
    Bradford-Extra-9 Bradford-Extra-A Bradford-Extra-B \
    Bradford-Extra-C Bradford-Extra-F Bradford-Extra-J \
    Bradford-Extra-K Bradford-Extra-L Bradford-Extra-M \
    Bradford-Extra-N Bradford-Extra-O Bradford-Extra-P \
    Bradford-Extra-S Bradford-Extra-T \
    \
    Bradford-Greek \
    \
    Bradford-Kazmiruk-T Bradford-Kazmiruk-O \
    Bradford-Kazmiruk-M \
    \
    DMP2000 \
    DMP3000-NLQ DMP3000-NLQ-Italic DMP3000-NLQ-Extra DMP3000-Draft-Extra \
    DMP3160-NLQ DMP3160-NLQ-Italic DMP3160-Draft DMP3160-Draft-Italic \
    NLQ401 NLQ401-Draft NLQ401-Draft-Extra \
    \
    ZXSpectrum-Chargen \
    Atari-Graphic \
    \
    Default8x9 \
    Default8x16 \
    Lat1-08 \
    Goha-12 Goha-14 Goha-16 \
    GohaClassic-12 GohaClassic-14 GohaClassic-16 \
    \
    Gohufont-11 Gohufont-11-Bold Gohufont-14 Gohufont-14-Bold \
    Gohufont-Uni-11 Gohufont-Uni-11-Bold Gohufont-Uni-14 Gohufont-Uni-14-Bold \
    \
    Monobook-12 Monobook-16 Monobook-20 Monobook-24 Monobook-28 \
    Monobook-16-Bold Monobook-20-Bold Monobook-24-Bold Monobook-28-Bold \
    \
    Old-Hylian-Draft Old-Hylian-NLQ Old-Hylian-NLQ-Elite Old-Hylian-NLQ-Dense \
    \
    Taiogeuna-Draft Taiogeuna-NLQ \
    \
    Braille-Draft \
    \
    7seg-Boxy-Draft 7seg-Boxy-NLQ 7seg-Boxy-NLQ-Rounded \
    7seg-Boxy-Narrowed-Draft 7seg-Boxy-Narrowed-NLQ 7seg-Boxy-Narrowed-NLQ-Rounded \
    7seg-Mini-Draft \
    \
    14seg \
    \
    Russian-Postcode-Draft Russian-Postcode-Tall-Draft \
    Russian-Postcode-NLQ Russian-Postcode-Tall-NLQ

.PHONY: overviews
overviews: $(foreach font, $(OVERVIEWED_FONTS), overviews/$(font).pdf overviews/$(font).ps)

## Let the PostScript overviews depend ond all the charsets needed by their
## respective PXF files

include overviews/charset.dep

deps:
	overviews/charset.dep.sh

# cancel a rather bizarre builtin rule of GNU Make
%: %.sh

## The generation templates

overviews/%.ps: %.pxf
        # We'll pass -R. to Pixitie even though it already has the font.  This
        # is to ensure that it uses the external, not the embedded version of
        # relevant resources.  (Recall that external resources take precedence
        # over internal ones.)
	./pixitie -R. --showcase $(basename $<) > $@


overviews/%.pdf: overviews/%.ps
        # Apple's pstopdf is often, but not always, able to perform the
        # conversion.  It particularly seems to have trouble with fonts larger
        # than 255 (sic) glyphs.
        #
        # We'll rely on GhostScript's ps2pdf, which is more reliable.
	ps2pdf $< $@

