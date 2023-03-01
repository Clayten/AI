class UserProfile
  def self.unrated_beliefs
    ["Life has a purpose.",
     "Everyone should be treated equally.",
     "We should strive to do our best.",
     "People should have the right to choose their own destiny.",
     "Money can't buy happiness.",
     "It is important to be kind and generous.",
     "We are all connected.",
     "We should strive to make the world a better place.",
     "We should take responsibility for our actions.",
     "It is important to respect others and their beliefs.",
     "We are all unique and special in our own way.",
     "We should strive for harmony and peace.",
     "We should strive to be honest and truthful.",
     "We should be tolerant of different cultures and beliefs.",
     "We should take care of our planet.",
     "We should strive for excellence in all areas of life.",
     "We should strive to be open-minded and accepting of others.",
     "We should strive to be compassionate and forgiving.",
     "We should strive to be self-aware and mindful of our actions.",
     "We should strive for balance in all aspects of our lives.",
     "We should strive for personal growth and development.",
     "We should be mindful of our thoughts and words.",
     "We should be tolerant and accepting of different lifestyles.",
     "We should strive to be non-judgmental and accepting of others."]
  end
	def self.positive_beliefs
		["Life is unfair.",
		 "People are untrustworthy.",
		 "There is no hope for the future.",
		 "Money is the only way to success.",
		 "The world is a dangerous place.",
		 "People are out to get you.",
		 "Life is a struggle.",
		 "People are selfish.",
		 "No one cares about you.",
		 "You can't make a difference.",
		 "Poverty is inevitable.",
		 "Success comes at the expense of someone else.",
		 "Everyone has an agenda.",
		 "Things will never get better.",
		 "Life is meaningless.",
		 "Other people's opinions are more important than yours.",
		 "There is no such thing as justice.",
		 "People are fundamentally flawed.",
		 "Change is impossible.",
		 "You can't have it all."]
	end
	def self.negative_beliefs
		["Everyone is capable of achieving greatness.",
		 "Life is full of endless possibilities.",
		 "Kindness is the most powerful force in the world.",
		 "Everyone has the power to make a difference.",
		 "People can learn from their mistakes.",
		 "Every day is an opportunity for growth.",
		 "The future is bright.",
		 "We can create a better world for ourselves and future generations.",
		 "We are all connected in some way.",
		 "We can overcome any obstacle.",
		 "Everyone deserves to be happy.",
		 "Love will always prevail.",
		 "Happiness is a choice.",
		 "We are all capable of achieving our dreams.",
		 "Miracles can happen.",
		 "We can create our own destiny.",
		 "Life is worth living.",
		 "Every cloud has a silver lining.",
		 "There is always hope.",
		 "Success is possible no matter the circumstances."]
	end
	def self.beliefs ; unrated_beliefs + positive_beliefs + negative_beliefs end
  def self.traits
		["Loyal",
		 "Dependable",
		 "Kind",
		 "Passionate",
		 "Ambitious",
		 "Generous",
		 "Creative",
		 "Intelligent",
		 "Optimistic",
		 "Courageous",
		 "Responsible",
		 "Humble",
		 "Open-minded",
		 "Patient",
		 "Tactful",
		 "Hard-working",
		 "Impulsive",
		 "Empathetic",
		 "Self-confident",
		 "Sociable",
		 "Resilient",
		 "Humorous",
		 "Resourceful",
		 "Insightful",
		 "Organized"]
	end

		def self.ideologies
			["Liberalism",
			 "Conservatism",
			 "Socialism",
			 "Anarchism",
			 "Marxism",
			 "Libertarianism",
			 "Fascism",
			 "Nationalism",
			 "Environmentalism",
			 "Humanism",
			 "Feminism",
			 "Catholicism",
			 "Buddhism",
			 "Atheism",
			 "Islam"]
		end
		def self.areas_of_knowledge
			["Mathematics",
			 "Science",
			 "Language",
			 "Technology",
			 "History",
			 "Geography",
			 "Psychology",
			 "Philosophy",
			 "Economics",
			 "Law",
			 "Sociology",
			 "Anthropology",
			 "Politics",
			 "Religion",
			 "Literature",
			 "Art",
			 "Music",
			 "Architecture",
			 "Engineering",
			 "Medicine",
			 "Education",
			 "Agriculture",
			 "Business",
			 "Astronomy",
			 "Physics",
			 "Chemistry",
			 "Biology",
			 "Nutrition",
			 "Journalism"]
		end
		def lookup n
			thoughts.find {|k,v| v[n] }&.last&.send(:[], n)
		end
	
		def fix_data_keynames *qs
			$qs = qs
			if qs.length == 1 && qs.first =~ /,/
				qs = qs.first
				qs = qs.gsub(/[^\w ,]/,'')
				qs = qs.split(/\s*,\s*/)
			end
			qs
		end

		def get *ns
			ns = fix_data_keynames *ns
			data = ns.flatten.map {|n| [n, lookup(n)] }
			desc = data.map {|n,v| "#{n}: #{v}" if v }.compact.join(', ')
		end

		def provide_requested_data *qs
			qs = fix_data_keynames *qs
			traits, ideologies, knowledge = %w(traits ideologies knowledge).map {|pr| props = thoughts[pr.to_sym] ; qs.map {|q| next unless v = props[q] ; [q, v] }.compact.map {|k,v| "#{k}: #{v}" }.join(', ') }
			[traits, ideologies, knowledge].reject(&:empty?).join(', ')	
		end

		def describe
			traits, ideologies, knowledge = %w(traits ideologies knowledge).map {|x| thoughts[x.to_sym].keys.sort.join(', ') }
			<<~USER
				Exhibits some amount of: #{traits}
				Holds views for or against: #{ideologies}
				Has an ammount of nowledge in: #{knowledge}
			USER
		end

		def rnd_support ; ('%.3f' % (rand * 2 - 1)).to_f end
		def rnd_ammount ;            rand(1000) / 1000.0 end

		attr_reader :thoughts
		def initialize
			@thoughts = {
				traits:                 Hash[self.class.traits.sample(10).map {|n| [n, rnd_ammount] }],
				ideologies:         Hash[self.class.ideologies.sample(10).map {|n| [n, rnd_support] }],
				knowledge:  Hash[self.class.areas_of_knowledge.sample(10).map {|n| [n, rnd_ammount] }],
			}
		end

	def self.prompt_needed_information user:, belief:
		labels = user.thoughts.values.map(&:keys).sample(3).map(&:to_s).join(', ')
		example = <<~E
		#UserData
		#{example}
		#Reasoning
		This data is important because it may indicate beliefs towards religion.
		E
		"A user #{user.describe}\nYour job is to analyze the following question and determine which which of this user data is important to know in answering the question: 'Is the user likely to hold the following belief: #{belief}\nDo not answer the question, answer with the list of user data you will need.\n#{example}\n"
	end

	def self.prompt_reason_about_belief requested_data:, belief:
		"You have asked for and been given this data about traits, ideologies, and areas of knowledge and how much the user exhibits these: #{requested_data} on a scale where -1 is against, 0 is neutral, and 1 is in support of. Beware that the user's sentiment may be negative - they may hold a counter view. Use this information to determine and explain your thinking behind whether the user is likely to hold the following belief: #{belief}\nAnswer in the following format: Answer: (yes/no), Confidence in your answer: (0 - 1), Explanation: (Why you conclude this.)"
	end

	def self.ask txt, model: nil, max_tokens: nil
		model ||= 'text-davinci-003'
		max_tokens ||= 250
		OpenAI.ask txt, model: model, max_tokens: max_tokens
	end

	def self.ask_about_a_belief belief: nil, user: nil, model: nil, max_tokens: nil
		user ||= new
		belief ||= beliefs.sample
		puts "Determine if user would support the belief: #{belief}"
		data_request = ask prompt_needed_information(user: user, belief: belief), model: model, max_tokens: max_tokens
		requested_data = user.get data_request

		puts "Requested data: #{requested_data}"

		r = ask prompt_reason_about_belief(requested_data: user.get(data_request), belief: belief), model: model, max_tokens: 350
		puts r.strip
	end
	def self.c ; Kernel.xyz end
	def self.b &x ; c &x end
	def self.a &x ; b &x end
end
