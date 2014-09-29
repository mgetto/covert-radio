require 'yaml'

# Radio that allows to listen to internet radio stations.
# Mplayer must be installed
# Will only run on linux (maybe unix-like) systems
class CovertRadio

	# Set everything up.
	def initialize

		# File definitions
		@station_file = '/opt/covert-radio/var/station_list.yml'
		@mp_control_file = '/tmp/mp-control'
		@mp_info_file = '/tmp/mp-info'
		@mp_error_file = '/tmp/mp-error'

		# Load Station yaml
		@stations = YAML.load_file(@station_file)

		# Test if the mplayer instance is active and get process id(s) if so
		mplayer_running_raw = `lsof |grep mplayer |grep /tmp/mp-control |awk '{print $2}'`
		@mp_pids = mplayer_running_raw.split "\n"
		@mp_running = mplayer_running_raw && mplayer_running_raw != ""
	end

	# Print a list of stations (Really handy for autocompletion)
	def stations
		@stations.each { |station|
			puts station["name"]
		}
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

		File.delete @mp_info_file
		File.delete @mp_error_file
		File.delete @mp_control_file
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
			# Create control file (named pipe / fifo)
			if not File.exist?(@mp_control_file)
				`mkfifo #{@mp_control_file}`
			end
			# Create info and error file
			if not File.exist?(@mp_info_file)
				`touch #{@mp_info_file}`
			end
			if not File.exist?(@mp_error_file)
				`touch #{@mp_error_file}`
			end
			
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
