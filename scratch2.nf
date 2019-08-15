parent_contig_folder = './test-data/contigs'


Channel.fromPath( "${parent_contig_folder}/*/contigs.fasta")
  .map{ f -> tuple((f.baseDir).baseName, file(f))}
  // .ifEmpty { exit 1, "params.EF_path was empty - no input files supplied" }
  .subscribe{ println it }
  // .view{}
  // .into { contig_folder_ch; contig_folder_to_print }


// println contig_folder_ch

// contig_folder_to_print
//   .subscribe{ println it }
