# Running the script
The CLI is pretty similar to what is described in the original prompt. However there are two new flags to determine the working hours we're searching for. Both `--start` and `--end` are optional and can be used in any order. Some examples of how to use the script are:

- `ruby availability.rb Maggie,Nick`
- `ruby availability.rb John,Joe,Emily --start=14`
- `ruby availability.rb Jane,Jordan,Maggie,Joe --start=14 --end 22`


# Taking this to production
My mindset while writing this script was to simulate what I would do in a production environment as much as possible. However, there were some tradeoffs I made considering the limited data set and knowledgeable user base.

## Data Model
I kept the data fairly sparse in this script to focus on the business logic of determining availability. In production I would expect `User` and `Event` to be tables/models along with an additional join table between users and events as both users and events could have many of each other. I would also store working hours on the `User` table to allow a user to set their own schedule.

## Script Efficiency
Because of the limited data set I opted for a slightly more inefficient solution. In production I would expect this script to query a database, or cache, and utilize primary keys instead of names. I'd also reformat how we're comparing events, by fetching all of the relevant user events for the day (or days) and analyzing the potential gaps instead of looking at all of a user's events for every possible time block.

## User Interface
For the purposes of this exercise it makes sense to print the result of finding the availability between user's. In production I'd expect this script to return an array of `Availability` objects that is served to a client via a json api. The client could then use that data to warn about conflicts.

## Error Handling
I included a couple of errors to prevent the calculator from operating with missing or invalid data. In production I would include more validations/errors on the existence of the users and whether the passed number makes sense in comparison with the other working hours. For example, `--start` should not be a number greater than `--end` and `--end` should not be smaller than `--start`.

## Code Style
Normally I'd separate the structs and classes used in this script into separate files and write robust tests. The prompt was simple enough that I felt like it was a little overkill to separate the objects used for the business logic from the actual execution of the script. In production I would expect the `\app` structure to look something like this:

```
-\models
  - user.rb
  - event.rb
  - user_events.rb
  - availability.rb
-\services
  - calculate_availability.rb
-\controllers
  - availability_controller.rb
```

# General Thoughts
I enjoyed putting together the code for this challenge. The prompt was complex enough to encompass all of the aspects of what production level software should look like. I hope what I've presented gives you a sense of the kind of engineer I am. Thank you for the opportunity and I look forward to hearing your feedback!
