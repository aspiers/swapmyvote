# This loads the tactical voting recommandations from StopTheTories.vote
# into the recommendations table

require_relative("tactical_vote_stt_csv")
require_relative("mysociety_constituencies_csv")

class TacticalVoteSttRecs
  attr_reader :advisor, :mysoc_constituencies

  ACCEPTABLE_NON_PARTY_ADVICE = [:heart, :none]
  SMV_CODES_BY_ADVICE_TEXT = {
    lab: :lab,
    snp: :snp,
    ld: :libdem
  }

  def initialize
    @advisor = TacticalVoteCsv.new
    @mysoc_constituencies = MysocietyConstituenciesCsv.new
  end

  # rubocop:disable Metrics/MethodLength
  def load
    ons_id_by_mysoc_short_code = {}

    mysoc_constituencies.each do |constituency|
      ons_id_by_mysoc_short_code[constituency[:short_code]] = constituency[:ons_id]
    end

    parties_by_smv_code = Party.all.each_with_object({}) do |party, lookup|
      lookup[party.smv_code.to_sym] = party
    end

    non_tory_parties = Party.all.select { |p| p.smv_code != "con"}

    not_recognised = Set.new

    advisor.data.each do |row|
      ons_id = ons_id_by_mysoc_short_code[row[:mysoc_short_code]]
      rec_key = { constituency_ons_id: ons_id, site: advisor.site }
      rec = Recommendation.find_or_initialize_by(rec_key)
      source_advice = row[:advice]

      # ------------------------------------------------------------------------

      canonical_advice = source_advice.downcase.parameterize(separator: "_").to_sym
      party_smv_code = SMV_CODES_BY_ADVICE_TEXT[canonical_advice]
      non_party_advice = ACCEPTABLE_NON_PARTY_ADVICE.include?(canonical_advice) ? canonical_advice : nil

      if party_smv_code && parties_by_smv_code[party_smv_code]
        rec.text = party_smv_code.to_s.titleize
        party = parties_by_smv_code[party_smv_code]
        rec.update_parties( [party.id] )
      elsif non_party_advice && non_party_advice == :heart
        rec.text = "Any"
        rec.update_parties( non_tory_parties.map(&:id) )
      else
        # if we can't turn it into a recommendation we must delete any existing entry
        unless rec.id.nil?
          rec.update_parties( [] ) # keep none, delete the rest
          rec.delete
          print "X" # to signify delete
        end

        not_recognised.add({ advice: source_advice })

        next
      end

      # ------------------------------------------------------------------------

      rec.link = advisor.link
      rec.save
      print "." # to signify update
    end

    puts "\n\nVoting advice not recognised #{not_recognised.to_a}" if not_recognised.size.positive?
  end
end
