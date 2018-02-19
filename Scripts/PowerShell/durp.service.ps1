<#
  Copyright (c) 2017-2018 Francois Gendron <fg@frgn.ca>
  GNU Affero General Public License v3.0

  durp.service.ps1
  PowerShell service that downloads upvoted reddit pictures of tracked subreddits


  ToDo:
  url that do not end with file extension
  list of feed to pull json file from
#>

################################################################################
# Folder where to download pictures
$downloadFolder = "D:\frgnca\Images\durp"

# Link of private feed to pull json file from (see your https://www.reddit.com/prefs/feeds/)
$jsonLink = ""

# List of tracked subreddits
$trackedList = "
Art
aww
"

# Supported file extension list
$extensionList = "
avi
bmp
gif
gifv
jpg
jpeg
mkv
mov
mp4
mpeg
png
"

# Wait time in seconds between each check from the service for a change in state
$refreshRate = 1
########################
# Run continuously to act as a service/daemon
while($true)
{
	# Get json file and convert to object
	$durp = Invoke-WebRequest $jsonLink | ConvertFrom-Json

    # If json has changed
    if($durp.data.after -ne $old_durp_data_after)
    {
        # Json has changed
        
        # Save data from new json to compare later
        $old_durp_data_after = $durp.data.after

	    # Get list of upvotes
	    $upvoteList = $durp.data.children

	    # For each upvote in the list of upvotes
	    foreach($upvote in $upvoteList)
	    {
            # If it is the last most recent upvote
            if($upvote.data.id -eq $most_recent_upvote)
            {
                # It is the last most recent upvote

                # Stop checking for new upvotes
                break
            }
            else
            {
                # It is not the last most recent upvote

                # Get current data
		        $current_subreddit = $upvote.data.subreddit
		        $current_url = $upvote.data.url

                # Find current url extension
		        $current_urlExtension = $current_url.Substring($current_url.LastIndexOf(".") + 1) 

		        # If tracked subreddits list contains current subreddit, and supported extension list contains current url extension
		        if( ($trackedList -like "*$current_subreddit*") -and ($extensionList -like "*$current_urlExtension*") )
		        {
			        # Tracked subreddits list contains current subreddit, and supported extension list contains current url

			        # Get current data
			        $current_permalink = $upvote.data.permalink

			        # Create filename path from current permalink
			        # Remove last character which is always "/"
			        $filename = $current_permalink.Substring(0, $current_permalink.Length - 1)
			        # Find position of now last "/"
			        $position = $filename.LastIndexOf("/")
			        # Replace this "/" with "_" to become allowed filename
			        $filename = $filename.Remove($position, 1).Insert($position, "_")
			        # Find position of now last "/"
			        $position = $filename.LastIndexOf("/")
			        # Keep only text from that point
			        $filename = $filename.Substring($position + 1)
			        
                    # If the extension is gifv from Imgur.com
                    if($current_urlExtension -eq "gifv")
                    {
                        # The extension is gifv

                        # Replace by mp4 in filename
                        $current_urlExtension = "mp4"

                        # Replace by mp4 in current url
                        $current_url = $current_url.Replace("gifv", "mp4")
                    }

                    # Add file extension
			        $filename = $filename+"."+$current_urlExtension
			        # Add subreddit
			        $filename = $filename.Insert(0, $current_subreddit+"\")
			        # Add full path
			        $filename = $downloadFolder+"\"+$filename
		
			        # Create sureddit folder path
			        $subredditFolder = $downloadFolder+"\"+$current_subreddit

			        # If subreddit folder does not already exists
			        if(-not (Test-Path $subredditFolder))
			        {
				        # Subreddit folder does not already exists

				        # Create subreddit folder
				        New-Item $subredditFolder -type directory
			        }

			        # Download file in subreddit folder
			        Invoke-WebRequest -Uri $current_url -OutFile $filename 
		        }
            }
	    }

        # Save data from new most recent upvote to compare later
        $most_recent_upvote = $upvoteList[0].data.id
    }
    else
    {
        # Json has not changed

        # Wait
        sleep $refreshRate
    }
}
