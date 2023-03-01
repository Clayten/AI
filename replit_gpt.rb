#!/usr/bin/env ruby

require 'httpx'

module OpenAI
  def key ; ENV["OPENAI_API_KEY"] end

  def completion_url ; 'https://api.openai.com/v1/completions' end
  def  embedding_url ; 'https://api.openai.com/v1/embeddings' end

  def completion_models
    {'text-davinci-003':  {price: 0.1200, tokens: 4000},
     'text-curie-001':    {price: 0.0120, tokens: 2048},
     'text-babbage-001':  {price: 0.0024, tokens: 2048},
     'text-ada-001':      {price: 0.0016, tokens: 2048}
    }
  end

  def embedding_models
    {'text-embedding-ada-002':  {price: 0.1200, tokens: 4000},
    }
  end

  def cheapest_completion_model ; completion_models.sort_by {|k,v| v[:price] }.first.first end
  def cheapest_embedding_model  ;  embedding_models.sort_by {|k,v| v[:price] }.first.first end

  def header ; {Authorization: "Bearer #{key}"} end

  def post url, header, data
    $r = resp = HTTPX.post url, headers: header, json: data
    JSON.parse resp.body.to_s
  end

  def complete txt, temperature: 0.6, max_tokens: 1500, model: nil
    raise "unknown model #{model}" if model && !completion_models[model.to_sym]
    model ||= cheapest_model
    $data = data = {prompt: txt, temperature: temperature, model: model, max_tokens: max_tokens}
    $resp = resp = post url, header, data
  end

  def embedding txt, temperature: 0.6, max_tokens: 1500, model: nil
    raise "unknown model #{model}" if model && !embedding_models[model.to_sym]
    model ||= cheapest_model
    $data = data = {input: txt, temperature: temperature, model: model, max_tokens: max_tokens}
    $resp = resp = post url, header, data
  end

  def ask question, model: nil
    complete(question, model: model)['choices'].first['text']
  end

  def embed text, model: nil
    embedding(text, model: model)['choices'].first['text']
  end

  def repl
    loop do
      print "Question: "
      question = gets.strip
      break if answer =~ /^(exit|quit)/i
      answer = ask(prompt_assistant_coder + ' ' + question)
      # response = openai.Completion.create( model="text-davinci-002", prompt=prompt, temperature=0, max_tokens=512, stop='```', )
      # embedding = openai.Embedding.create( response.response )
      puts "Intermediate answer: #{answer}"
      output = capture_stdout { exec answer }
      puts "Program output: #{output}"
      puts
    end
  end
  extend self
end

OpenAI.repl
