# Tactic-Teamwork

Easily import Tactic times into Teamwork.

## Usage

Start your Tactic entry titles with `[teamwork-project-id]`, or `[teamwork-project-id/teamwork-task-id]`.

Then, export your Tactic entries into a `tactic-entries.csv` and run the following command :

```sh
$ bin/tactic_to_teamwork import your/folder/tactic-entries.csv --token=your-teamwork-token --domain=myteamworksubdomain
```

All the Tactic entries following the rules detailed above will be imported into Teamwork.

Once done, a log file is generated in `log/` directory.

## Revert

In case you have imported wrong data, you can revert an import using its log file :

```sh
$ bin/tactic_to_teamwork revert logs/import_file_log.txt
```
