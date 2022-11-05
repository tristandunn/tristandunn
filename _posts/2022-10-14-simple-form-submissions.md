---
title: "Simple Form Submissions"
image: "posts/2022-10-14/image@2x.png"
category: netlify
subtitle: "Accept form submissions for free, even on static websites."
description: "How to accept basic form submissions for free."
permalink: /journal/simple-form-submissions/
---

Form submission websites are abundant, but can be overkill for most situations,
such as static websites. They can also become expensive and limit your ability
to process or access your data. While they do allow you to avoid writing code
and supporting the infrastructure, you can use [Netlify][] and [GitHub][] to
accept over 100,000 submissions per month for free with less than 35 lines of
code. And you gain complete access to your data and the ability to customize it
any way you would like.

**Note:** Netlify providing 125,000 requests and 100 hours of function runtime
per month and local submissions taking ~50ms resulted in the 100,000 submissions
per month estimate. The submissions per hour limit is 5,000 due to GitHub's rate
limiting.
{: class="note"}

## Installing the Dependencies

To start, let's set up a local development environment with the necessary
dependencies. We're going to use the [Netlify CLI][] to allow us to test the
submission function locally before deploying to production, but it's optional.

```json
{
  "scripts": {
    "start": "netlify dev"
  },
  "dependencies": {
    "qs": "6.11.0",
    "octokit": "2.0.9"
  },
  "devDependencies": {
    "netlify-cli": "12.0.9"
  }
}
```
{: caption="Creating the `package.json` file."}

The two required dependencies are `qs` and `octokit`, which allow parsing of the
raw query string and adding the submission data to a GitHub repository
respectively.

## Building the Function

Next up is writing the code for the [Netlify Function][] to parse the submitted
form data and add it as a file to a GitHub repository.

First we'll create a `netlify/functions/submit.js` file for the function and
require our two dependencies.

```javascript
const { Octokit } = require("octokit"),
  qs = require("qs");
```
{: caption="Creating the `netlify/functions/submit.js` file and requiring the
dependencies."}

Next we can create a simple function handler that redirects to the root of the
website. In the future you could adjust the redirect based on the data
submitted, such as forwarding certain submissions to a meeting scheduling
website.

```javascript
const { Octokit } = require("octokit"),
  qs = require("qs");

exports.handler = async (event) => {
  return {
    "headers": {
      "location": "/"
    },
    "statusCode": 301
  };
};
```
{: lines="4-12" caption="Adding a function handler to redirect."}

Now that we have a handler we can start parsing the data and generating a
prettier version of the content. The prettier content is optional, but can make
it a bit easier to read if you're not using a program to parse the data.

```javascript
exports.handler = async (event) => {
  const data = qs.parse(event.body),
    content = JSON.stringify(data, null, 2);

  return {
    // ...
  };
};
```
{: lines="2-3" caption="Parsing the data and generating prettier content."}

Now we can create a GitHub API client and add the content to a repository's
file. While this is by far the most overwhelming part of the code, the majority
of the variables are requirements of the GitHub API endpoint.

```javascript
exports.handler = async (event) => {
  // ...

  const octokit = new Octokit({ "auth": process.env.GITHUB_API_TOKEN });

  await octokit.rest.repos.createOrUpdateFileContents({
    "author": {
      "email": process.env.GITHUB_USER_EMAIL,
      "name": process.env.GITHUB_USER_NAME
    },
    "branch": process.env.GITHUB_BRANCH,
    "committer": {
      "email": process.env.GITHUB_USER_EMAIL,
      "name": process.env.GITHUB_USER_NAME
    },
    "content": Buffer.from(`${content}\n`, "utf-8").toString("base64"),
    "message": `Add submission from ${data.email}.`,
    "owner": process.env.GITHUB_OWNER,
    "path": `submissions/${Date.now()}.json`,
    "repo": process.env.GITHUB_REPOSITORY
  });

  // ...
};
```
{: lines="3-20" caption="Adding the submission data to a file in a GitHub
repository."}

We'll cover the environment variables in the next section, but for now the more
interesting bits are the `content`, `message`, and `path` options.

- The `content` is what the file will contain. We're using the prettier data we
  generated before, but we must encode it in [Base64][] format for the GitHub API
  to accept it.
- The `message` is the commit message on GitHub, and while it doesn't have to be
  unique it can be nice to include the e-mail or other data in it for historical
  purposes.
- The `path` is where the file will be in the repository, with the one
  rule being that it's unique. If you expect a high number of
  simultaneous submissions you may want to add randomness to avoid conflicts.

{% comment %}
```javascript
const { Octokit } = require("octokit"),
  qs = require("qs");

exports.handler = async (event) => {
  // Parse the submission form body.
  const data = qs.parse(event.body);

  // Format the parsed submission data.
  const content = JSON.stringify(data, null, 2);

  // Create a GitHub client with a GitHub API token.
  const octokit = new Octokit({ "auth": process.env.GITHUB_API_TOKEN });

  // Create a file containing the formatted submission data on GitHub within a
  // `submissions` directory using the current time as the filename.
  await octokit.rest.repos.createOrUpdateFileContents({
    "author": {
      "email": process.env.GITHUB_USER_EMAIL,
      "name": process.env.GITHUB_USER_NAME
    },
    "branch": process.env.GITHUB_BRANCH,
    "committer": {
      "email": process.env.GITHUB_USER_EMAIL,
      "name": process.env.GITHUB_USER_NAME
    },
    "content": Buffer.from(`${content}\n`, "utf-8").toString("base64"),
    "message": `Add submission from ${data.email}.`,
    "owner": process.env.GITHUB_OWNER,
    "path": `submissions/${Date.now()}.json`,
    "repo": process.env.GITHUB_REPOSITORY
  });

  // Redirect back to the root page.
  return {
    "headers": {
      "location": "/"
    },
    "statusCode": 301
  };
};
```
{: caption="Adding the form submission function in the
`netlify/functions/submit.js` file."}
{% endcomment %}

## Defining Environment Variables

Back to the environment variables we skipped in the previous section, which are
all used for adding the submission to GitHub. See the [GitHub documentation][]
for all the options.

If you're deploying, you should set the [environment variables in Netlify][].
If you're testing locally, the Netlify CLI will automatically load an `.env`
file. Here's a example with fake values:

```sh
GITHUB_API_TOKEN="example"           # A GitHub access token with `repo` permission.
GITHUB_BRANCH="submissions"          # Optional branch to add the submission to.
GITHUB_OWNER="username"              # The owner of the repository.
GITHUB_REPOSITORY="repository"       # The name of the repository.
GITHUB_USER_EMAIL="user@example.com" # The e-mail address for the author and committer.
GITHUB_USER_NAME="Example User"      # The username for the author and committer.
```
{: caption="Example `.env` file for local development."}

The one variable you can skip is the branch name. If it's excluded it will use
the default branch instead. If you trigger a build when a file changes, it might
be worth using a branch other than the default to avoid build on every
submission.

If you use a separate branch, you can create an empty, orphan branch without the
existing contents by using `git switch --orphan submissions-branch-name`.

## Ideas from Improvement

While the submissions will work as is, here are some ideas on how to improve the
submissions, the user experience, and handling the data.

### Validations

You could add a library, such as [validator.js][], to sanitize and check the
submission data to avoid invalid e-mails, missing input, etc. You should at
least verify the presence of any required fields and redirect with an error
when they're missing.

### User Experience

If you add validations, it'd be nice to improve the user experience with inline
errors instead of needing to handle a redirect. You could progressively enhance
the form with JavaScript, send the submission with [fetch][], and respond with
JSON instead of a redirect.

### Parsing the Submissions

With each submission in a separate file it may become difficult to handle using
the data. You could look into using [jq][] to extract the e-mails from all the
submissions and import into your newsletter, convert all the submissions into a
CSV to import into a spreadsheet, and so much more.

### Static Database

As mentioned before, if you rebuild the website when files change you could use
this to re-build the website on every submission. That means you can essentially
treat the submission files as a database, with a comment system being the
simplest example.

### Spam Prevention

Leaving a form open for submission is asking for spam and could result in
hitting GitHub API request limits or exceeding the free Netlify plan. You'll
want to add a [CAPTCHA][], display the form in certain conditions using
JavaScript, or use some other prevention method to prevent automated
submissions.

### Your Ideas

Let me know what ideas you come up with or how you're using Netlify and GitHub
together, with static websites or otherwise, [e-mail me][].

[Base64]: https://en.wikipedia.org/wiki/Base64
[CAPTCHA]: https://en.wikipedia.org/wiki/CAPTCHA
[GitHub documentation]: https://docs.github.com/en/rest/repos/contents#create-or-update-file-contents
[GitHub]: https://github.com
[Netlify CLI]: https://docs.netlify.com/cli/get-started/
[Netlify Function]: https://docs.netlify.com/functions/overview/
[Netlify]: https://netlify.com
[e-mail me]: mailto:hello@tristandunn.com
[environment variables in Netlify]: https://docs.netlify.com/environment-variables/overview/
[fetch]: https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch
[jq]: https://stedolan.github.io/jq/
[validator.js]: https://github.com/validatorjs/validator.js
