require 'HTTParty'
require 'Nokogiri'

class SimpleCrawler
   include HTTParty
   default_timeout 10

   def initialize
     @frontier = Array.new
     @repository = Array.new
     @max_repository = 100
   end
   # Inicialize frontier take urls to start the crawler
   def initialize_frontier(file_name = 'test_frontier.txt')
     #The frontier is clear
     @frontier = []
     File.open(file_name, "r") { |file|
       while (line = file.gets)
         # strip remove \n
         @frontier.push(line.strip)
       end
     }
     @frontier.uniq
   end

   def parse_links(link, domain)
     unless link.include?('http')
       #link = link.sub('#', domain.split(':')[0] + ':' + domain.split(':')[1].split('/')[0]) if link [0] == '#'
       link = domain.split(':')[0] + ':' + link if link[0] == '/' && link[1] == '/'
       link = domain + link if link[0] == '/' && link[1] != '/'
     end
     #link = domain + link if link[0] == '/' && link[1] != '/'
     # if link[0] == '/' && link[1] == '/'
     #   link = domain.split(':')[0] + ':' + link
     # end
     #puts "link : #{link} dominion : #{domain}"
     link
   end

   def scraper(page)
     type_accepted = ['http', 'https']
     @links = Array.new
     begin
       request = self.class.get(page)
       parse_page = Nokogiri::HTML(request)
       puts "Analizando pagina #{page}"
       parse_page.css('a').map do |link|
         link_parsed = parse_links(link['href'], page) if(link['href'] && page)
         if link_parsed && type_accepted.include?(link_parsed.split(':')[0])
           @frontier.push(link_parsed) if !((@frontier && @frontier.include?(link_parsed)) || (@repository && @repository.include?(link_parsed)))
         end
         @links.push(link_parsed)
       end
     rescue Exception => e
       puts "Pagina #{page} no accesible. Exception: #{e}"
     end
     @links.uniq
   end

   def crawler
     while @frontier.size > 0 && @repository.size < 100
       page = @frontier.pop
       if !@repository.include?(page)
         @repository.push(page)
         scraper(page)
       end
     end
   end

   def get_frontier
     @frontier
   end

   def get_repositoty
     @repository
   end

   def get_max_repository
     @frontier
   end

   def set_max_repository size
     @max_repository = size
   end
end

def test(seed_file = 'test_frontier.txt')
  c = SimpleCrawler.new
  puts(c.scraper('https://github.com/Pedroyz/Simple-Crawler-Ruby'))
  c.initialize_frontier(seed_file)
  c.crawler
  File.open('test_frontier_final.txt', 'w') do |file|
    c.get_frontier.each { |f| file.puts(f)}
  end
  File.open('test_repository.txt', 'w') do |file|
    c.get_repositoty.each { |r| file.puts(r)}
  end
end

if __FILE__ == $0
  test()
end
