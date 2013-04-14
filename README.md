### Crushpath Box Prototype App

The goal of the crushpath box prototype application is to investigate how we can allow our users to share files and
measure the responses from prospective buyers such as: views and downloads.

Crushpath users will be able to "Pitch" files. Assume, the pitched files will be shown on the pitch site.
Once visitors come and open the link the proper stats will be augmented.

Every night the Crushpath user will get an email if there was any new activity

### Architecture

- Sinatra Application
- Uses Box API
- Backend is done in MongoDB
- Views use Haml
- Emailing is done via Pony gem

### Status Update from Vinu

All the files have a pitch button against them so far.

If you click the pitch button, a new folder called crush_pitch is created, if it doesn't exist. 
If it exists, the file is copied to the pitch

Heroku App : [Box App](http://whispering-tor-4545.herokuapp.com)

### To Run locally:

#### First Time

``` bash
$ bundle install
```

Currently API Value is set in the app.
This will be changed to ENV later

Error Handling has to be done !! Pending

Email is using pony and gmail SMTP

Have to manually set the gmail and password in environment variables before running the app

```bash
export GMAIL_SMTP_USER='Gmail email id'
export GMAIL_SMTP_PASSWORD='Gmail Password'
```

#### Gotchas
Since folders are set as session variables, it is going to throw some exceptions of existing folder as it is resetted every time the app is started. Will be handled soon!
