#! /usr/bin/env ruby
# coding: utf-8

# This script takes the JSON-like text dump generated 
# by 1Password's Export function on STDIN and outputs
# keepassx v1 xml on STDOUT.
#

require 'json'
require 'erb'

# mapping of groups to keepassx icons
@group_icons = {
  internet: 1,
  email: 19,
  ssh: 30,
  wallet: 66,
  notes: 56,
  software: 67,
  databases: 43,
  misc: 0
}

def h(s)
  CGI::escapeHTML s.to_s
end

def format_time(t)
  Time.at(t).strftime '%Y-%m-%dT%H:%M:%S'
rescue ''
end

# this maps 1password items to keepassx groups
def determine_type(name, location)
  case name
  when /(genericaccount|unixserver)/i
    :ssh
  when /database/i
    :databases
  when /email/i
    :email
  when /webform/i
    location.to_s =~ /(google|mail)/i ? :email : :internet
  when /financial/i, /government/i, /reward/i
    :wallet
  when /securenote/i
    :notes
  when /license/i
    :software
  else
    :misc
  end
end

def format_comment(text)
  if text && !text.empty?
    "<br/>" + text.gsub("\n", '<br/>')
  else
    ''
  end
end

def parse_record(line)
  data = JSON.parse line
  #puts data.inspect
  secured = data['secureContents']
  open = data['openContents']
  username, password = if fields = secured.delete('fields')
    u = fields.detect{|f|f['designation'] == 'username'}['value'] rescue nil
    p = fields.detect{|f|f['designation'] == 'password'}['value'] rescue nil
    [u, p]
  else
    [secured.delete('username'), secured.delete('password')]
  end
  notes = secured.delete 'notesPlain'
  secured.delete 'passwordHistory'
  comment = secured.map{|k,v| h("#{k}: #{v}") unless k =~ /html/}.join("<br/>")
  comment << format_comment(notes)
  if open
    open.delete 'scope'
    if tags = open.delete('tags')
      comment << "<br/>" << "tags: #{tags.join(', ')}"
    end
    comment << "<br/>" << open.map{|k,v| h("#{k}: #{v}") unless k =~ /hash/i}.join('<br/>')
  end
  {
    title: data['title'],
    url: data['location'],
    username: username,
    password: password,
    created_at: format_time(data['createdAt']),
    updated_at: format_time(data['updatedAt']),
    type: determine_type(data['typeName'], data['location']),
    comment: comment,
    trashed: data['trashed']
  }
end

erb_template = <<-END
<!DOCTYPE KEEPASSX_DATABASE>
<database>
<% @data.each do |name, entries| %>
 <group>
  <title><%= h name %></title>
  <icon><%= @group_icons[name] %></icon>
  <% entries.each do |entry|  %>
  <entry>
   <title><%= h entry[:title] %></title>
   <username><%=h entry[:username] %></username>
   <password><%=h entry[:password] %></password>
   <url><%=h entry[:url] %></url>
   <comment><%= entry[:comment] %></comment>
   <icon><%= @group_icons[entry[:type]] %></icon>
   <creation><%= entry[:created_at] %></creation>
   <lastmod><%= entry[:updated_at] %></lastmod>
   <expire>Never</expire>
  </entry>
  <% end %>
 </group>
<% end %>
</database>
END

@data = Hash.new{|h, k| h[k] = []}
STDIN.each_line do |l|
  unless l[0..2] == '***'
    r = parse_record(l)
    if r[:trashed]
      STDERR.puts "skipping deleted entry #{r[:title]}"
    else
      @data[r[:type]] << r
    end
  end
end
#puts data.inspect

STDERR.puts "#{@data.values.inject(0){|sum, i| sum + i.size}} items"
@data.each do |g, items|
  STDERR.puts "#{g}: #{items.size}"
end
puts ERB.new(erb_template).result(binding)

