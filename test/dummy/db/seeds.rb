names = ["PT Sinar Abadi", "PT Maju Jaya", "CV Kreatif Nusantara", "PT Teknologi Andalan", "PT Samudra Logistik", "PT Bumi Hijau", "PT Cahaya Retail", "PT Mitra Finansial"]
statuses = %w[active active active pending inactive blocked active active]
companies = names.each_with_index.map do |n, i|
  Company.create!(name: n, status: statuses[i], credit_limit: (i + 2) * 250_000_000, active: statuses[i] == "active")
end
rng = Random.new(42)
60.times do |i|
  status = LoanRequest::STATUSES.sample(random: rng)
  created = rng.rand(0..330).days.ago
  LoanRequest.create!(company: companies.sample(random: rng), amount: rng.rand(5..90) * 1_000_000, status: status,
                      disbursed_on: (status == "disbursed" ? created.to_date + 2 : nil), notes: "Request #{i + 1}",
                      created_at: created)
end
