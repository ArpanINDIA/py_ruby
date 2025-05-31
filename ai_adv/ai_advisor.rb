class AIAdvisor
  def initialize(user)
    @user = user
  end

  def spending_advice
    transactions = @user.transactions.last(30)
    prompt = "Analyze these transactions: #{transactions.to_json}. Provide 3 personalized savings tips."
    
    openai_client = OpenAI::Client.new
    response = openai_client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )
    
    response.dig("choices", 0, "message", "content")
  end
end