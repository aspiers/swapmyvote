SELECT count(users.id) AS total,
       ons_constituencies.name AS Constituency,
       preferred.name AS Preferred,
       willing.name AS Willing
FROM parties AS willing,
     parties AS preferred, users
LEFT OUTER JOIN ons_constituencies
ON users.constituency_ons_id = ons_constituencies.ons_id
WHERE willing_party_id = willing.id
  AND preferred_party_id = preferred.id
GROUP BY ons_constituencies.name, preferred.name, willing.name
ORDER BY total DESC, ons_constituencies.name;
