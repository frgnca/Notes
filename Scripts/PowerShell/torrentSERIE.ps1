<#
  Copyright (c) 2017-2018 Francois Gendron <fg@frgn.ca>
  GNU Affero General Public License v3.0

  torrentSERIE.ps1
  PowerShell script to download TV series via torrent


  Requirements: -PsTorrent <https://github.com/assives/PsTorrent>
                -A torrent client that supports magnet links
#>

################################################################################
# Hardcode video quality to search for
$VideoQuality = "720p"
########################

# Function to query EZTV and clean up what it returns
function QueryEZTV ($SearchTerm)
{
	# Make initial query to EZTV using entered serie name
	$InitialResults = Search-EZTV -Query $SearchTerm

	# Only keep results of the targeted video quality and with the correct ShowName
	$CleanResults = $InitialResults | Where {$_.QualityInfo -like "*$VideoQuality*" -and $_.ShowName -like "*$SerieName*"}
	
	# Return the cleaned up results
	return($CleanResults)
}

# Loop
while($true)
{	
	# Get the name of the serie to search for
	$SerieName = Read-Host "Serie name"

	# Check if a serie name was entered
	if($SerieName)
	{
		# A serie name was entered
		
		# Get the number of the season to search for
		$SeasonNumber = Read-Host "Season number"

		# Check if a season number was entered
		if($SeasonNumber)
		{
			# A season number was entered
			
			# Get the number of the episode to search for
			$EpisodeNumber = Read-Host "Episode number"

			# Check if an episode number was entered
			if($EpisodeNumber)
			{
				# An Episode number was entered

				# Get serie results
				$Serie = QueryEZTV($SerieName)
				
				# Get the episodes related to this season of the serie
				$Season = $Serie | Where {$_.Season -eq $SeasonNumber}
				
				# Get the results related to this episode of this season of the serie
				$Episode = $Season | Where {$_.Episode -eq $EpisodeNumber}
				
				# The results will be everything related to this episode of this season of the serie
				$Results = $Episode
			}
			else
			{
				# No episode number was entered

				# Get serie results
				$Serie = QueryEZTV($SerieName)
				
				# Get the results related to this season of the serie
				$Season = $Serie | Where {$_.Season -eq $SeasonNumber}

				# The results will be everything related to this season of the serie
				$Results = $Season
			}
		}
		else
		{
			# No season number was entered

			# Get serie results
			$Serie = QueryEZTV($SerieName)
			
			# The results will be everything related to the serie
			$Results = $Serie
		}
	}
	else
	{
		# No serie name was entered
		
		# End the script
		return
	}
	
	# Get user selection among results
	$Selected = $Results | Out-GridView -Passthru
	
	# Download selected results
	$Selected | Start-MagnetLink
	
	# Add spacing between searches
	write-host "`n"
}
