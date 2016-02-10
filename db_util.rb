#!/usr/bin/ruby
# chkconfig: 2345 93 22
# description: This will ensure that a dbdump is carried out every 30 minutes.
# processname: dbdump

#############################################
# This passage to keep 2 daemon instances
# from running at the same time
# only one is allowed to run
##############################################

count = 0
IO.popen('ps -ef | grep dbdump | grep -v grep').each{|i|
  count = count.next
  if count > 1
    case ARGV.first
      when 'status'
        puts '---------'
      when 'stop'
        puts "+++++++++"
      when 'start'
        puts "Another dbdump daemon is running.. exiting.."
        exit 0
      when 'restore'
        puts '---------'
    end
  end
}

class Restore
  @ns = nil

  class << self
    def instance_id
      ##################################
      # Grabs the instance id
      # of the mysql container
      ##################################

      count = 0

      IO.popen("docker ps | grep mysql").each{|i|
        #count = count.next
        puts i.split[0]
        @instance = i.split[0]

      }
    end

    def get_pid
      #########################################
      # Get Pid to execute commands via nsenter
      #########################################
      IO.popen("docker inspect #{@instance}").each{|i|
        puts @ns = i.split[1].chomp(',') if i =~ /"Pid":/

        #puts "Initiated Replication for Instance ID: #{ns}"
      }
    end

    def restore_db
      ##############################################
      #
      # This method will allow you to restore a dbdump
      # should something happen to the  current db
      # It will take a local dump and restore it to
      # the mysql container
      #
      ##############################################
      hostname = `hostname`.strip
      database1 = "what_ever_db"
      database2 = "what_ever_db"

      IO.popen("nsenter -m -i -n -p -u -t #{@ns} <<!
mysql -e 'CREATE DATABASE IF NOT EXISTS #{database1}; use #{database1}; source /var/lib/mysql/#{database1}_db_dump_#{hostname}.sql;'
mysql -e 'CREATE DATABASE IF NOT EXISTS #{database2}; use #{database2}; source /var/lib/mysql/#{database2}_db_dump_#{hostname}.sql;'
mysql -e 'show databases;'
!
").each{|i|
        puts i
      }
    end

    def push
      ####################################
      # This method allows you to push a mysqldump to any
      # database
      # either by doing:
      # dbdump push (interactively enter hostname)
      # or
      # dbdump push <server-name>
      #####################################
      if ARGV[1] == nil
        #################
        # If no argument is given then it will prompt for a hostname to push dbdump to
        #################
        database1 = "what_ever_db"
        database2 = "what_ever_db"
        begin
          puts "Which Server would like to have db dump pushed to? "
          db = $stdin.gets
          dump_to_backup = %Q(mysqldump #{database1} | mysql -u root -h '#{db.chomp}' centro)
          puts "Pushing db dump to #{db}"
          IO.popen(dump_to_backup).each{|i| puts i }
          IO.popen("mysql -u root -h #{db.chomp} -e 'show databases'").each{|i| puts i}
        rescue
          puts "Please ensure that the host that you are trying to push to has mysql running"
        end
      else
        begin
          ######################
          # If an argument is given then it will push dbdump to the host given from command line
          ######################
          dump_to_backup = %Q(mysqldump centro | mysql -u root -h '#{ARGV[1]}' centro)
          puts "Pushing db dump to #{ARGV[1]}"
          IO.popen(dump_to_backup).each{|i| puts i }
          puts "Databases on #{ARGV[1]}"
          puts "*"*20
          IO.popen("mysql -u root -h #{ARGV[1]} -e 'show databases'").each{|i| puts i}

        rescue
          puts "Please check if host exists.."
        end
      end
    end


    def start_daemon
      database1 = "what_ever_db"
      database2 = "what_ever_db"
      dump_dumps = %Q(
mysqldump -u root #{database1} > /var/lib/mysql/#{database1}_db_dump_`hostname`.sql
mysqldump -u root #{database2} > /var/lib/mysql/#{database2}_db_dump_`hostname`.sql
)
      Process.daemon #Daemonizing this script
      loop{
        IO.popen(dump_dumps).each{|i|
          puts i
        }
        sleep 1800
      }
    end

    def stop_daemon
      e = `pgrep dbdum`.strip.to_i
      # Killing the process
      puts "Killing.. " + e.to_s
      Process.kill("HUP", e)
    end

    def status
      puts "dbdump process: "
      puts `ps -ef | grep dbdump | grep -v grep`
      IO.popen('lsof').each{|i|
        puts i if i =~ /centro|jbpm5/
      }
    end
  end
end




case ARGV.first
  when "push"
    Restore.push
  when "start"
    Restore.start_daemon
  when "stop"
    Restore.stop_daemon
  when "status"
    Restore.status
  when "restore"
    Restore.instance_id
    Restore.get_pid
    Restore.restore_db
  else
    puts "Usage:
  dbdump start : starts the dbdump daemon
  dbdump stop : will kill the dbdump daemon
  dbdump status : will give a status of dbdump
  dbdump restore : restore databases
  "
end
