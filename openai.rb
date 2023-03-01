#!/usr/bin/env ruby

require 'httpx'
require 'pry'

class ::Logger
	def output progname = nil, &block ; add OUTPUT, nil, progname, &block end
	def output? ; true ; end
	def output! ; true ; end
end
module ::Logger::Severity ; OUTPUT rescue OUTPUT = UNKNOWN end

load '~/dev/ascii/colors.rb'

module CH
  module OpenAI
    def completion_url ; 'https://api.openai.com/v1/completions' end
    def  embedding_url ; 'https://api.openai.com/v1/embeddings'  end
    def     models_url ; 'https://api.openai.com/v1/models'      end
    def      edits_url ; 'https://api.openai.com/v1/edits'       end

    def models_fn ; File.join(File.dirname(__FILE__), 'models.json') end
    def fetch_models ; get models_url end
    def write_models json ; File.write(models_fn, json) end
    def       models force_update: false
      if !File.exist?(models_fn) || force_update
        write_models fetch_models
      end
      JSON.load_file models_fn
    end

    def completion_models
      {'text-davinci-003':  {price: 0.1200, tokens: 4000},
       'text-curie-001':    {price: 0.0120, tokens: 2048},
       'text-babbage-001':  {price: 0.0024, tokens: 2048},
       'text-ada-001':      {price: 0.0016, tokens: 2048},
       'code-davinci-002':  {price: 0.0024, tokens: 8000},
       'code-cushman-001':  {price: 0.0016, tokens: 2048},
      }
    end

    def  embedding_models
      {'text-embedding-ada-002':  {price: 0.0004, tokens: 8191}, }
    end

    def     edits_models
      {'text-davinci-edit-001':  {price: 0.0004, tokens: 8191},
       'code-davinci-edit-001':  {price: 0.0004, tokens: 8191},
      }
    end

    def cheapest_completion_model ; completion_models.sort_by {|k,v| v[:price] }.first.first end
    def cheapest_embedding_model  ;  embedding_models.sort_by {|k,v| v[:price] }.first.first end
    def best_completion_model ; 'text-davinci-003' end
    def best_embedding_model  ; embedding_models.keys.first end

    def api_key ; ENV["OPENAI_API_KEY"] end
    def token   ; "Bearer #{api_key}" end
    def header  ; {Authorization: token} end

    def logger ; AI.logger end

    def get url, data = {}
      data = data.merge header
      p [:get, :u, url, :d, data]
      logger.info({request: data, time: Time.now}.inspect + "\n")
      # $resp = resp = HTTPX.get url, params: data
      $resp = resp = HTTPX.get url, headers: data
      puts "Warn: API returned error code #{resp.status}" unless (200..299).include?(resp.status)
      $body = body = resp.body.to_s
      $json = json = JSON.parse body
      logger.info({response: json, time: Time.now}.inspect + "\n")
      json
    end

    def post url, header, data
      # p [:post, :u, url, :h, header, :d, data]
      logger.info({request: data, time: Time.now}.inspect + "\n")
      $resp = resp = HTTPX.post url, headers: header, json: data
      puts "Warn: API returned error code #{resp.status}" unless (200..299).include?(resp.status)
      $body = body = resp.body.to_s
      $json = json = JSON.parse body
      logger.info({response: json, time: Time.now}.inspect + "\n")
      json
    end

    def complete txt, temperature: 0.6, max_tokens: 1500, model: nil
      # raise "unknown model #{model}" if model && !completion_models[model.to_sym]
      model ||= cheapest_completion_model
      $completions ||= []
      $completions << [txt, temperature, max_tokens, model]
      $req_data  =  req_data = {prompt: txt, temperature: temperature, model: model, max_tokens: max_tokens}
      $resp_data = resp_data = post completion_url, header, req_data
      $request_log ||= []
      $request_log << [req_data, resp_data]
      resp_data
    end

    def embedding txt, temperature: 0.6, max_tokens: 1500, model: nil
    #   raise "unknown model #{model}" if model && !embedding_models[model.to_sym]
      model ||= cheapest_embedding_model
      $req_data  =  req_data = {input: [txt], temperature: temperature, model: model, max_tokens: max_tokens}
      $resp_data = resp_data = post embedding_url, header, req_data
    end

    def check_for_errors resp
      return unless  e = resp['error']
      raise "API: Returned error '#{e['message']}', '#{e['type']}'"
    end

    def ask question, model: nil, max_tokens: nil
      $question = question
      $api_answer = api_answer = complete(question, model: model, max_tokens: max_tokens)
      check_for_errors api_answer
      $response = api_answer['choices'].first['text']
    end

    def embed text, model: nil
      $answer = embedding(text, model: model)['data'].first['embedding']
    end

    # ruby code ~3.6B/t
    def token_length text, model: 'text-embedding-ada-002'
      embedding(text, model: model)['usage']['total_tokens']
    end

    extend self
  end

  module AI
    def cosine_similarity v1, v2
      dp = v1.zip(v2).inject(0) {|a,(n1, n2)| a + n1 * n2 }
      a = v1.map {|n| n ** 2 }.sum
      b = v2.map {|n| n ** 2 }.sum
      dp / (Math.sqrt(a) * Math.sqrt(b))
    end

    def prompt_assistant_coder
      # You are a skilled programming-based assistant and you write Ruby programs to answer user queries. Your output must consist entirely of executable Ruby code and will be executed to provide the user's answer.
      # You are a skilled programming-based assistant and you write Ruby programs to answer user queries. First under a section called 'Problem:' restate the problem, then under a section called 'Methodology:' describe the means and methods, then under a header called 'Solution:', inside a markdown code block, write a ruby program which will be run to provide the user's answer. Please stick strictly to the requested response format. Question:
      # You are a skilled programming-based assistant and you write Ruby programs to answer user queries. Return your answer in markdown. In a 'Problem' section restate the query, in a 'Methodology' section explain the steps and why, in a 'Code' section, inside a code block, write a Ruby program which will be run to provide the user's answer. The code section must contain only a code block. Please stick strictly to the requested format to aid parsing. Question:
      <<~PROMPT
      You are a skilled programming-based assistant and you write Ruby programs to answer user queries. Return your answer in markdown format. 
      In a #Problem section, restate the query. 
      In a #Methodology section, explain the steps and reasoning behind your solution. 
      In a #Code section, write only a Ruby program inside a code block to provide the answer. 
      Stick strictly to the requested format to aid parsing. Do not include any other sections. Do not write anything except a code block in the Code section. Make your whole answer valid Markdown.
      If you define a Ruby method, don't forget to call it!
      The point of the example is to demonstrate the effect, not simply the use of a method. That means the code block must make the start state clear and the result of code execution should demonstrate the effect.

      Example OpenAI Response:
      -----
      #Problem
      A restatement of the user's query
      #Methodology
      A description of how the code will work
      #Code
      ```ruby
      VALID_RUBY_CODE
      ```
      -----

      User's Question:
      PROMPT
    end

    def form_programming_question txt
      "#{prompt_assistant_coder.strip} '#{txt}'"
    end

    def environment
      @execution_environment ||= 'foo'
    end
    def run code
      ret = capture_streams(:stdout, :stderr, :tee_output) { environment.instance_eval code }
      puts "=> #{ret[:return]}" if ret[:return]
      ret[:stdout]
    end

    def regex_codesection_header
      /(^#\s?code.?\n)/i
    end

    def parse_markdown_code_section txt
      return [txt, nil] unless txt =~ /`\n*$/ # If it doesn't end in some number of `s, it's not in a codeblock
      $c = code_parser = /(?<backticks>`+)?((?<lang>\w+)\n)?(?<code>.*?)(\k<backticks>)\n*$/m
      code, lang = txt.match(code_parser).named_captures&.values_at('code', 'lang')
      [code.strip, lang]
    end

    def parse_mixed_response answer
      $r = response_parser = /^(?<body>.*?)#{regex_codesection_header}(?<code>.*)$/mi
      desc, code_section = answer.match(response_parser).named_captures.values_at('body', 'code')
      $resp_desc, $resp_code = desc, code_section
      code, lang = parse_markdown_code_section code_section
      [desc, code]
    end

    def repl
      loop do
        print "Question: ".red
        question = gets.strip
        break if question =~ /^(exit|quit)/i
        prompted_question = form_programming_question question
        puts "Full prompted question: #{prompted_question}"
        $answer = ask prompted_question, model: best_completion_model
        txt, code = parse_mixed_response(answer)
        $txt, $code = txt, code
        if txt && code
          puts "Intermediate answer: #{txt.green}"
          puts "Code:\n```\n#{code.blue.bold}\n```"
        else
          puts "Intermediate answer: #{answer}"
          code = answer
        end
        puts "Program output:".white
        $output = output = run code
        puts
      end
    end

    def chunkify content
      chunks = []
      chunk = ''
      lines = content.lines
      while !lines.empty? do
        lines.delete_if {|l|
          chunk += l
          # p [:l, l, :cl, chunk.length]
          break if chunk.length > 2500
          true
        }
        # p [:ll, lines.length, :cl, chunk.length]
        chunks << chunk
        chunk = ''
      end
      chunks
    end

    def summarize_file fn, content, model: best_completion_model
      p [:sum_file, fn, model]
      chunks = chunkify content

      prompt = <<~TXT
        You are a highly skilled and meticulous Ruby developer. You are translating a Python project to Ruby.
        We need a detailed summary of the code. Please carefully fill out this form with what you learn.

        Review Form - finish filling this out.

        Reviewer: #{model}
        File: #{fn}
        Chunk #: {NUM}
        Textual Summary:
        Symbols Defined:

        --- Review code below this line ---
        {CONTENT}
      TXT
      chunks.each_with_index.map {|chunk, num|
        $chunk = chunk
        p [:sum_file_chunk, num]
        pr = prompt.dup
        pr.sub!('{NUM}', (num + 1).to_s)
        pr.sub!('{CONTENT}', chunk)
        # ask pr, model: model
        ask "You are a skilled Ruby developer. Translate this code to Ruby as best as you can.\n#{chunk}", model: model
      }
    end

    def summarize_file_list files
    end

    def shorten_file_names filen
    end
    
    def summarize_project dir, model: nil
      files = Dir.glob(File.join dir, '**/*py').reject {|f| f =~ /(tests)/ }
      contents = files.map {|file|
        content = File.read file
        fn = file[dir.length..-1]
        [fn, content]
      }
      $f = files
      c = contents.map(&:last).join
      p [:sum_project, dir, :num_files, files.length, :content_length, c.lines.length, c.length]
      summaries = contents[2..2].map {|file, content| summarize_file file, content, model: model }
    end

    def cli
      binding.pry
    end

    def logger
      @logger ||=
        begin
          f = File.join File.dirname(__FILE__), 'conversations.txt'
          l = Logger.new(f)
          l.formatter = proc {|_,_,_,msg| ; puts msg ; msg }
          l
        end
    end

    def rl ; load __FILE__ end

    extend OpenAI
    extend self
  end
end

CH::AI.cli if __FILE__ == $0
