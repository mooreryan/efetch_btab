#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

require "abort_if"

include AbortIf

cmd = "\\curl --silent 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?retmode=text&rettype=fasta&db=protein&id=%s' | grep -v ^$"


ARGV.each do |fname|
  AbortIf.logger.info { "Reading btab '#{fname}'" }

  ids = []
  idx = 0
  File.open(fname).each_line do |line|
    idx += 1
    if (idx % 1000).zero?
      STDERR.printf("reading btab line %d\r", idx)
    end

    query, target, *rest = line.chomp.split "\t"

    id = target.match(/ref_([NY]P_[0-9]+\.[0-9])_/)

    if id
      ids << id[1]
    else
      AbortIf.logger.warn { "Target #{target} couldn't find ID" }
    end
  end

  AbortIf.logger.info { "Fetching slices" }

  slices = ids.each_slice(100)
  num_slices = slices.count

  outf = fname + ".target_proteins.fa"
  File.open(outf, "w") do |f|
    idx = 0
    slices.each do |ary|
      idx += 1
      STDERR.printf("fetching slice %d of %d (%.2f%%)\r",
                    idx,
                    num_slices,
                    idx / num_slices.to_f * 100)

      sleep 0.3
      f.puts `#{cmd % ary.join(",")}`
    end
  end

  AbortIf.logger.info { "Wrote #{outf}" }
end
