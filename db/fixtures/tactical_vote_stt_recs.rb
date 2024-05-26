# This loads the tactical voting recommandations from StopTheTories.vote
# into the recommendations table

require_relative('tactical_vote_stt_csv')
require_relative('mysociety_constituencies_csv')

class TacticalVoteSttRecs

  ACCEPTABLE_NON_PARTY_ADVICE = ["None"]
  attr_reader :advisor, :mysoc_constituencies

  def initialize
    @advisor = TacticalVoteCsv.new
    @mysoc_constituencies = MysocietyConstituenciesCsv.new("db/fixtures/mysociety_parl_constituencies_2025.csv")
  end

  def load
    ons_id_by_mysoc_short_code = {}

    mysoc_constituencies.each do |constituency|
      # puts constituency
      ons_id_by_mysoc_short_code[constituency[:short_code]] = constituency[:ons_id]
    end

    not_recognised = Set.new

    advisor.data.each do |row|
      ons_id = ons_id_by_mysoc_short_code[row[:mysoc_short_code]]
      rec_key = { constituency_ons_id: ons_id, site: advisor.site }
      rec = Recommendation.find_or_initialize_by(rec_key)
      rec.text = row[:advice]

      if rec.text == ""
        # if there is right now no recommendation and we loaded from the DB, we must delete
        rec.delete unless rec.id.nil?
        next
      end

      rec.link = advisor.link
      party_short_code = rec.party_short_code_from_text

      rec.save

      if party_short_code.nil? && !ACCEPTABLE_NON_PARTY_ADVICE.include?(rec.text)
        not_recognised.add({advice: rec.text, party_short_code: party_short_code} )
      end
    end

    if not_recognised.size > 0
      puts "Voting advice not recognised #{not_recognised.to_a}"
    end
  end

end
