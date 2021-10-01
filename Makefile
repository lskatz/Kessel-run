SOFTWARE="Kessel-Run"

.DELETE_ON_ERROR:

DONEFILES=MLST.db/Acinetobacter_baumannii.chewbbaca/.done MLST.db/Arcobacter_butzleri.chewbbaca/.done MLST.db/Brucella_melitensis.chewbbaca/.done MLST.db/Campylobacter_jejuni.chewbbaca/.done MLST.db/Escherichia_coli.chewbbaca/.done MLST.db/Listeria_monocytogenes.chewbbaca/.done MLST.db/Salmonella_enterica.chewbbaca/.done MLST.db/Streptococcus_agalactiae.chewbbaca/.done MLST.db/Streptococcus_pyogenes.chewbbaca/.done MLST.db/Yersinia_enterocolitica.chewbbaca/.done

all: $(DONEFILES) containers/shovill-v1.1.0.cif containers/chewbbaca-v2.8.4-1.cif
	@echo "Done. MLST.db should have ChewBBACA-formatted databases, and singularity containers should be in the containers folder"

clean: 
	rm -rf MLST.db containers

speciesList.tsv:
	wget 'https://chewbbaca.online/api/NS/api/species/list' -O - > chewbbaca.species.json
	./scripts/chewiejson.pl < chewbbaca.species.json > $@.tmp
	mv -v $@.tmp $@
MLST.db: 
	mkdir -pv $@

containers:
	mkdir -pv $@

containers/shovill-v1.1.0.cif: containers
	singularity build $@ docker://staphb/shovill:1.1.0

containers/chewbbaca-v2.8.4-1.cif: containers
	singularity build $@ docker://ummidock/chewbbaca:2.8.4-1

MLST.db/%.chewbbaca/.done: MLST.db speciesList.tsv
	# TODO need to remake dirname etc to match .done
	db=$$(dirname $@) && \
	dir=$$(dirname $$db) && \
	name=$$(basename $$db .chewbbaca) && \
	id=$$(grep $$name speciesList.tsv | cut -f 2) && \
	cd MLST.db && \
	wget -O species$$id.zip "https://chewbbaca.online/api/NS/api/species/$$id/schemas/1/zip?request_type=download" && \
	mkdir $$id.chewbbaca && \
  mv -v species$$id.zip $$id.chewbbaca/ && \
  cd $$id.chewbbaca && unzip -q species$$id.zip && cd - && \
	trn=$$(\ls $$id.chewbbaca/*.trn) && \
	b=$$(basename $$trn .trn) && \
	target=$$b.chewbbaca && \
	mv $$id.chewbbaca $$target -nv && \
	cd $$target && git init && git add -v * .genes_list .ns_config .schema_config && \
	git commit -m init && \
	git tag --force v1 && cd -; 
	touch $@

