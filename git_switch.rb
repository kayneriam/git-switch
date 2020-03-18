# frozen_string_literal: true

require 'json'

# Git Account Switcher
module GitSwitch
  DEFAULT_ACCOUNTS_FOLDER = File.join ENV['HOME'], '.accounts'
  DEFAULT_ACCOUNTS_FILE = 'git.json'.freeze

  class << self
    include GitSwitch
  end

  def list
    path = File.join DEFAULT_ACCOUNTS_FOLDER, DEFAULT_ACCOUNTS_FILE
    JSON.parse(File.read(path), symbolize_names: true)[:accounts].each do |acc|
      puts "name: #{acc[:name]} \t email: #{acc[:email]}"
    end
  end

  def next
    path = File.join DEFAULT_ACCOUNTS_FOLDER, DEFAULT_ACCOUNTS_FILE
    accounts = JSON.parse(File.read(path), symbolize_names: true)[:accounts]
    current_name = `git config --global user.name`.chomp
    accounts.each_with_index do |account, index|
      next unless account[:name] == current_name

      if index == accounts.count - 1
        _switch accounts.first[:name], accounts.first[:email]
      else
        _switch accounts[index + 1][:name], accounts[index + 1][:email]
      end
      break
    end
    puts 'Switched to:'
    current
  end

  def prev
    path = File.join DEFAULT_ACCOUNTS_FOLDER, DEFAULT_ACCOUNTS_FILE
    accounts = JSON.parse(File.read(path), symbolize_names: true)[:accounts]
    current_name = `git config --global user.name`.chomp
    accounts.each_with_index do |account, index|
      next unless account[:name] == current_name

      if index.zero?
        _switch accounts.last[:name], accounts.last[:email]
      else
        _switch accounts[index - 1][:name], accounts[index - 1][:email]
      end
      break
    end
    puts 'Switched to:'
    current
  end

  def current
    puts "name: #{`git config --global user.name`}"
    puts "email: #{`git config --global user.email`}"
  end

  def add(name, email)
    path = File.join DEFAULT_ACCOUNTS_FOLDER, DEFAULT_ACCOUNTS_FILE
    accounts = JSON.parse(File.read(path), symbolize_names: true)[:accounts]
    accounts << { name: name, email: email }
    File.write path, { accounts: accounts }.to_json
  end

  def switch_by_name(name)
    account = _find_by_name name
    _switch account[:name], account[:email]
  end

  def switch_by_email(email)
    account = _find_by_email email
    _switch account[:name], account[:email]
  end

  def _switch(name, email)
    `git config --global user.name #{name}`
    `git config --global user.email #{email}`
  end

  def _find_by_name(name)
    path = File.join DEFAULT_ACCOUNTS_FOLDER, DEFAULT_ACCOUNTS_FILE
    JSON.parse(File.read(path), symbolize_names: true)[:accounts].each do |acc|
      return acc if acc[:name] == name
    end
  end

  def _find_by_email(email)
    path = File.join DEFAULT_ACCOUNTS_FOLDER, DEFAULT_ACCOUNTS_FILE
    JSON.parse(File.read(path), symbolize_names: true)[:accounts].each do |acc|
      return acc if acc[:email] == email
    end
  end

  def _setup
    folder_name = DEFAULT_ACCOUNTS_FOLDER
    path = File.join folder_name, DEFAULT_ACCOUNTS_FILE
    Dir.mkdir(folder_name) unless Dir.exist?(folder_name)
    File.write(path, { accounts: [] }.to_json) unless File.exist?(path)
    File.write(File.join(ENV['HOME'], '.bashrc'), "\nalias git-switch='ruby #{Dir.pwd}/#{__FILE__}'", mode: 'a')
  end

  def _clear
    path = File.join DEFAULT_ACCOUNTS_FOLDER, DEFAULT_ACCOUNTS_FILE
    File.write(path, { accounts: [] }.to_json)
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
when nil
  puts 'Empty command!'
else
  puts "Unknown command: #{ARGV[0]}"
end
