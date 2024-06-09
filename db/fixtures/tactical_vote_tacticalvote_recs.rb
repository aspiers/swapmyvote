# This loads the tactical voting recommandations from tactical.vote
# into the recommendations table

require_relative "tactical_vote_tacticalvote_csv"
require_relative "mysociety_constituencies_csv"

class TacticalVoteTacticalVoteRecs
  ACCEPTABLE_NON_PARTY_ADVICE = []
  SMV_CODES_BY_ADVICE_TEXT = {
    lib_dem: :libdem,
    labour: :lab,
    plaid: :plaid,
    green: :green,
    snp: :snp
  }

  attr_reader :advisor, :mysoc_constituencies

  def initialize
    @advisor = TacticalVoteTacticalVoteCsv.new
    @mysoc_constituencies = MysocietyConstituenciesCsv.new
  end

  # rubocop:disable Metrics/MethodLength
  def load
    ons_id_by_mysoc_name = {}

    mysoc_constituencies.each do |constituency|
      ons_id_by_mysoc_name[constituency[:name]] = constituency[:ons_id]
    end

    parties_by_smv_code = Party.all.each_with_object({}) do |party, lookup|
      lookup[party.smv_code.to_sym] = party
    end

    not_recognised = Set.new

    advisor.data.each do |row|
      ons_id = ons_id_by_mysoc_name[row[:constituency_name]]
      rec_key = { constituency_ons_id: ons_id, site: advisor.site }
      rec = Recommendation.find_or_initialize_by(rec_key)
      rec.link = advisor.link
      source_advice = row[:advice]

      # ------------------------------------------------------------------------

      canonical_advice = source_advice.strip.downcase.parameterize(separator: "_").to_sym
      party_smv_code = SMV_CODES_BY_ADVICE_TEXT[canonical_advice]

      if party_smv_code && parties_by_smv_code[party_smv_code]
        rec.text = party_smv_code.to_s.titleize
        party = parties_by_smv_code[party_smv_code]
        rec.update_parties([party])
      else
        # if we can't turn it into a recommendation we must delete any existing entry
        unless rec.id.nil?
          rec.update_parties([]) # keep none, delete the rest
          rec.delete
          print "X" # to signify delete
        end

        not_recognised.add({ advice: source_advice })

        next
      end

      # ------------------------------------------------------------------------

      rec.save!
      print "." # to signify update
    end

    puts "\n\nVoting advice not recognised #{not_recognised.to_a}" if not_recognised.size.positive?
  end
end
