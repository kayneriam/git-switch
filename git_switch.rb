# frozen_string_literal: true

require 'json'

# Git Accounts Switcher
module GitSwitch
  # Base path to accounts storage: /home/<username>/.accounts/git.json
  DEFAULT_ACCOUNTS_FOLDER = File.join ENV['HOME'], '.accounts'
  DEFAULT_ACCOUNTS_FILE = 'git.json'.freeze

  class << self
    include GitSwitch
  end

  def _switch(name, email)
    `git config --global user.name #{name}`
    `git config --global user.email #{email}`
    puts 'Switched to:'
    current
  end

  def _find_by_name(name)
    _accounts.each do |acc|
      return acc if acc[:name] == name
    end
  end

  def _find_by_email(email)
    _accounts.each do |acc|
      return acc if acc[:email] == email
    end
  end

  def _setup
    folder_name = DEFAULT_ACCOUNTS_FOLDER
    path = File.join folder_name, DEFAULT_ACCOUNTS_FILE
    Dir.mkdir(folder_name) unless Dir.exist?(folder_name)
    _clear unless File.exist?(path)
    File.write(File.join(ENV['HOME'], '.bashrc'), "\nalias git-switch='ruby #{Dir.pwd}/#{__FILE__}'", mode: 'a')
    `source #{File.join ENV['HOME'], '.bashrc'}`
  end

  def _clear
    _write({ accounts: [] }.to_json)
  end

  def _write(arg)
    path = File.join DEFAULT_ACCOUNTS_FOLDER, DEFAULT_ACCOUNTS_FILE
    File.write path, arg
  end

  def _accounts
    path = File.join DEFAULT_ACCOUNTS_FOLDER, DEFAULT_ACCOUNTS_FILE
    JSON.parse(File.read(path), symbolize_names: true)[:accounts]
  end

  def _help
    puts 'Options:'
    puts "\t* setup \t\t - Install git-switch and add alias to .bashrc"
    puts "\t* clear \t\t - Clear accounts storage"
    puts "\t* list \t\t\t - Show all accounts in storage"
    puts "\t* next \t\t\t - Choice next account in storage"
    puts "\t* prev \t\t\t - Choice previous account in storage"
    puts "\t* current \t\t - Show current account"
    puts "\t* <username> \t\t - Choice account by username"
    puts "\t* <email> \t\t - Choice account by email"
    puts "\t* add <username> <email> - Add account to storage"
  end

  def list
    accounts = _accounts
    accounts.each_with_index do |acc, index|
      puts "name:\t#{acc[:name]}\nemail:\t#{acc[:email]}"
      puts '' if index != accounts.count - 1
    end
  end

  def next
    accounts = _accounts
    current_name = `git config --global user.name`.chomp
    switch_trigger = false
    accounts.each_with_index do |account, index|
      next unless account[:name] == current_name

      if index == accounts.count - 1
        _switch accounts.first[:name], accounts.first[:email]
      else
        _switch accounts[index + 1][:name], accounts[index + 1][:email]
      end

      switch_trigger = true
      break
    end
    _switch(accounts[0][:name], accounts[0][:email]) unless switch_trigger
  end

  def prev
    accounts = _accounts
    current_name = `git config --global user.name`.chomp
    switch_trigger = false
    accounts.each_with_index do |account, index|
      next unless account[:name] == current_name

      if index.zero?
        _switch accounts.last[:name], accounts.last[:email]
      else
        _switch accounts[index - 1][:name], accounts[index - 1][:email]
      end

      switch_trigger = true
      break
    end
    _switch(accounts[0][:name], accounts[0][:email]) unless switch_trigger
  end

  def current
    puts "name: #{`git config --global user.name`}"
    puts "email: #{`git config --global user.email`}"
  end

  def add(name, email)
    accounts = _accounts
    accounts << { name: name, email: email }
    _write({ accounts: accounts }.to_json)
  end

  def switch_by_name(name)
    account = _find_by_name name
    _switch account[:name], account[:email]
  end

  def switch_by_email(email)
    account = _find_by_email email
    _switch account[:name], account[:email]
  end
end

case ARGV[0]
when 'setup'
  GitSwitch._setup
when 'add'
  GitSwitch.add ARGV[1], ARGV[2]
when 'next'
  GitSwitch.next
when 'prev'
  GitSwitch.prev
when 'list'
  GitSwitch.list
when 'clear'
  GitSwitch._clear
when 'current'
  GitSwitch.current
when 'help', nil
  GitSwitch._help
else
  if ARGV[0].include? '@'
    GitSwitch.switch_by_email ARGV[0]
  else
    GitSwitch.switch_by_name ARGV[0]
  end
end
