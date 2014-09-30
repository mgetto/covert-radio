require 'yaml'
require 'pathname'
require 'fileutils'

# Radio that allows to listen to internet radio stations.
# Mplayer must be installed
# Will only run on linux (maybe unix-like) systems
class CovertRadio

	# Set everything up.
	def initialize

		# File definitions
		@station_file = '/opt/covert-radio/var/station_list.yml'
		@tmp_directory = Pathname.new '/tmp/covert-radio'
		@mp_control_file = @tmp_directory + 'mplayer-control'
		@mp_info_file = @tmp_directory + 'mplayer-info'
		@mp_error_file = @tmp_directory + 'mplayer-error'
		@station_history_file = @tmp_directory + 'station_history'

		# Load Station yaml
		@stations = YAML.load_file(@station_file)

		# Test if the mplayer instance is active and get process id(s) if so
		mplayer_running_raw = `lsof |grep mplayer |grep #{@mp_control_file} |awk '{print $2}'`
		@mp_pids = mplayer_running_raw.split "\n"
		@mp_running = mplayer_running_raw && mplayer_running_raw != ""
	end

	# Print a list of stations (Really handy for autocompletion)
	def stations
		@stations.each { |station|
			puts station["name"]
		}
	end

	# Print the name of the current station
	def station
		exit if not @mp_running
		puts `tail #{@station_history_file} -n 1` 
	end

	# Print a list of stations (Really handy for autocompletion)
	def stationlist
		@stations.each { |station|
			puts station["name"]
			puts station["country"] if station["country"]
			puts station["lang"] if station["lang"]
			puts station["desc"] if station["desc"]
			puts ""
		}
	end

	# Pause (and unpause) playback
	def pause
		exit if not @mp_running
		send_command "pause"
	end

	# Turn off radio, shutdown mplayer, delete all temporary files
	def off
		exit if not @mp_running

		`kill #{@mp_pids[0]}` if @mp_pids[0]

		FileUtils.rm_rf @tmp_directory
	end

	# Start mplayer and listen to the given station
	# Only changes station if mplayer is already running
	def tune station

		station_result = @stations.select { |s| s["name"] == station}

		# Test if station is known
		if not station_result[0]
			puts "Sorry, no can do."
			exit
		end

		# Switch station if running
		if @mp_running
			send_command "loadfile #{station_result[0]["stream"]}"
		# Start mplayer if not
		else
			# Create directory for temporary files
			if not Dir.exist?(@tmp_directory)
				Dir.mkdir @tmp_directory
			end

			# Create control file (named pipe / fifo)
			if not File.exist?(@mp_control_file)
				`mkfifo #{@mp_control_file}`
			end
			# Create info and error file
			File.write(@mp_info_file, "")
			File.write(@mp_error_file, "")
			File.write(@station_history_file, "")
			
			# Query used to start mplayer
			# -quiet to supress noisy status updates
			# -slave activate control over named pipe
			# -input the named pipe to use
			# redirect standard output to info_file (contains ICY INFO)
			# redicert error output to error_file (normally you can ignore this file)
			start_mplayer_cmd = "mplayer -quiet -slave -input file=#{@mp_control_file} #{station_result[0]["stream"]} > #{@mp_info_file} 2> #{@mp_error_file}"

			# start mplayer in seperate process and detach it from the current one
			(pid = fork) ? Process.detach(pid) : exec(start_mplayer_cmd)
		end

		File.open(@station_history_file, 'a') { |file| file.write("#{station}\n") }
	end

	# output latest ICY INFO. (Song/Artist/Station info sent by station)
	def info n
		exit if not @mp_running
		puts `grep ICY #{@mp_info_file} | tail -n #{n} |awk -F\\' '{print $(2)}'`
	end

	# Helper to send commandos to mplayer (google for 'mplayer slave mode' to find a command overview)
	def send_command cmd
		output = open(@mp_control_file, "w+") # the w+ means we don't block
		output.puts cmd
		output.flush
		output.close
	end
end
