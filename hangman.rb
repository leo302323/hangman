require 'rest_client'
require 'byebug'

class Hangman
  attr_accessor :email, :word_dict, :char_dict, :server_url, :sessionId, :number_of_words, :number_of_guesses

  def initialize(email)
    self.email =  email
    self.server_url = 'https://strikingly-hangman.herokuapp.com/game/on'
  end

  def play_game
    self.word_dict = init_words_dict
    self.char_dict = init_chars_dict
    start_game
    1.upto number_of_words.to_i do |i|
      word = get_new_word
      puts "new word: #{word} #{i}"
      process_one_word(word,'',[],0,[])
    end
    score = get_score
    puts score
    submit_result if score > 1000
  end

  def process_one_word(word, last_result_word, tried_chars, wrong_guess, missing_chars)
    if !word.include?('*') || wrong_guess == 10
      puts word
      return
    end
    char_possible,missing_chars = get_possible_character(tried_chars, word, last_result_word, missing_chars)
    tried_chars << char_possible
    new_word, wrong_guess = guess_word(char_possible)
    puts new_word
    process_one_word(new_word, word, tried_chars, wrong_guess, missing_chars)
  end

  private

  def start_game
    req = {
        'playerId' => email,
        'action' => 'startGame'
    }
    response = RestClient.post(server_url,req.to_json)

    res_obj = JSON.parse response
    self.sessionId = res_obj['sessionId']
    self.number_of_words = res_obj['data']['numberOfWordsToGuess']
    self.number_of_guesses = res_obj['data']['numberOfGuessAllowedForEachWord']
  end

  def get_new_word
    req = {
        'sessionId' => sessionId,
        'action' => 'nextWord'
    }
    response = RestClient.post(server_url,req.to_json)

    (JSON.parse response)['data']['word']
  end

  def guess_word(char_possible)
    req = {
        'sessionId' => sessionId,
        'action' => 'guessWord',
        'guess' => char_possible
    }
    response = RestClient.post(server_url,req.to_json)

    result = (JSON.parse response)['data']
    [result['word'], result['wrongGuessCountOfCurrentWord']]
  end

  def get_score
    req = {
        'sessionId' => sessionId,
        'action' => 'getResult',
    }
    response = RestClient.post(server_url,req.to_json)

    (JSON.parse response)['data']['score']
  end

  def submit_result
    req = {
        'sessionId' => sessionId,
        'action' => 'submitResult'
    }
    response = RestClient.post(server_url,req.to_json)
    puts JSON.parse response
  end


  def get_possible_character(tried_chars, word, last_result_word, missing_chars)
    return [char_dict[word.length-1],missing_chars]  if tried_chars.size == 0
    if last_result_word == word # it means last guess missing
      missing_chars << tried_chars[-1]
    end
    reg_str = missing_chars.size == 0 ? '.{1}' : "[^#{missing_chars.join(' ')}]{1}"
    reg_ex = word.gsub('*',reg_str)
    possible_words = word_dict[word.length].grep Regexp.new(reg_ex)
    [top_character(possible_words, tried_chars), missing_chars]
  end

  def top_character(possible_words, tried_chars)
    max = 0
    top_char = ''
    total_str = possible_words.join('')
    (('A'..'Z').to_a - tried_chars).each do |c|
      count = total_str.count(c)
      if count > max
        top_char = c
        max = count
      end
    end
    top_char
  end

  def init_words_dict
    word_dict = {}
    File.open('./word_dict.txt') do |file|
      file.each do |line|
        line = line.strip.upcase
        if line.length > 0 && !line.include?("'")
          word_dict[line.length] = word_dict[line.length].nil? ? [line] : (word_dict[line.length] << line)
        end
      end
    end
    word_dict
  end

  def init_chars_dict
    ['A','A','A','A','S','E','E','E','E','E','E','E','I','I','I','I','I','I','I','I','E','E','E']
  end
end

Hangman.new('zlw302323@163.com').play_game