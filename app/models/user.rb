class User < ApplicationRecord
	has_secure_password

	validates :email, presence: true, uniqueness: {case_sensitive: false}
	validates :email, format: {with: /@/}

	before_save :downcase_email
	before_create :generate_confirmation_instructions

	def confirmation_token_valid?
		(self.confirmation_sent_at + 30.days) > Time.now.utc
	end

	def mark_as_confirmed!
		self.confirmation_token = nil
		self.confirmed_at = Time.now.utc
		save
	end

	private

	def downcase_email
		self.email = self.email.delete(' ').downcase
	end

	def generate_confirmation_instructions
		self.confirmation_token = SecureRandom.hex(10)
		self.confirmation_sent_at = Time.now.utc
	end
end
