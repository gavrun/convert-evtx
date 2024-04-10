# current directory of execution
$currentDirectory = Get-Location

# list of EVTX files in current directory
$evtxFiles = Get-ChildItem -Path $currentDirectory -Filter *.evtx

foreach ($evtxFile in $evtxFiles) {
    try {
        # start stopwatch to measure elapsed time
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # open EVTX file for streaming
        $eventReader = [System.Diagnostics.Eventing.Reader.EventLogReader]::new([System.Diagnostics.Eventing.Reader.EventLogQuery]::new($evtxFile.FullName, [System.Diagnostics.Eventing.Reader.PathType]::FilePath))

        # empty array to store events
        $events = @()

        # variables for progress tracking
        $outputFilePath = [System.IO.Path]::ChangeExtension($evtxFile.FullName, "txt")

        # read events from the EVTX file and process them
        while ($event = $eventReader.ReadEvent()) {
            $events += $event
            # convert events to text and append to output file
            $event | Format-List | Out-File -FilePath $outputFilePath -Append # Format-Table -AutoSize
            # update progress bar
            Write-Progress -Activity "Processing $($evtxFile.Name)" -Status "Writing to text file $($outputFilePath)" 
        }

        Write-Host "DEBUG: Elapsed time: $($stopwatch.Elapsed.TotalSeconds) seconds"

        # fail if elapsed time exceeds certain threshold (e.g., 300 seconds)
        if ($stopwatch.Elapsed.TotalSeconds -gt 300) {
            Write-Host "Error: Reading events from $($evtxFile.Name) took longer than 300 seconds"
            break
        }
        
        # stop stopwatch
        $stopwatch.Stop()

        Write-Host "Text file created: $outputFilePath"
    } catch {
        Write-Host "Error occurred while processing $($evtxFile.Name): $_"
    }
}
