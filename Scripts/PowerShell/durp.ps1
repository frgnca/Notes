<#
  Copyright (c) 2017 Francois Gendron <fg@frgn.ca>
  GNU Affero General Public License v3.0

  durp.ps1
  PowerShell script that downloads upvoted reddit pictures of tracked subreddits


  ToDo:
  add support for 4 character extensions
  add support for url that do not end with file extension
  add support for feed list to pull json file from
#>

################################################################################
# List of tracked subreddits
$trackedList = "
Art
aww
"

# Folder where to download pictures
$downloadFolder = "D:\frgnca\Images\durp"

# Link of private feed to pull json file from (see your https://www.reddit.com/prefs/feeds/)
$jsonLink = ""

# Supported file extension list
$extensionList = "
bmp
gif
jpg
png
"
########################
# Convert json file to object
$durp = Invoke-WebRequest $jsonLink | ConvertFrom-Json

# Get list of upvotes
$upvoteList = $durp.data.children

# For each upvote in the list of upvotes
foreach($upvote in $upvoteList)
{
	# Get current data
	$current_subreddit = $upvote.data.subreddit
	$current_url = $upvote.data.url

	# Find current url extension
	$current_urlExtension = $current_url.Substring($current_url.Length - 3, 3) # ToDo: add support for 4 character extensions

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
		# Replace "/" with "_"
		$filename = $filename.Remove($position, 1).Insert($position, "_")
		# Find position of now last "/"
		$position = $filename.LastIndexOf("/")
		# Keep only text from that point
		$filename = $filename.Substring($position + 1)
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
