# The Father Watson Guide: A Framework for Reflective Inquiry

## The Motivation: Accreting Understanding, Not Just Activity
Most workflows (like Agile standups) ask two questions: *What did you do? What are you doing next?* 

This is an **Activity Trap**. It measures progress by how many things you’ve made or how much code you’ve written. But when you are solving hard problems, researching, or designing, progress isn't about accreting *artifacts*—it is about accreting **understanding**. 

The Father Watson method forces you to practice **Reflective Inquiry** (thinking about your thinking). By explicitly identifying the boundaries of your knowledge, you "agenda-ize" your background thinking. Your brain will passively work on the gaps you’ve clearly defined. 

### How this differs from other frameworks (like OODA)
*   **OODA (Observe, Orient, Decide, Act)** is a *reactive and tactical* loop. It was built for fighter pilots to outmaneuver an opponent in a rapidly changing environment. 
*   **The Watson Method** is a *reflective and generative* loop. It is built for navigating ambiguity, deep work, and design. In OODA, action is the goal. In Watson, **inquiry is the driver**; activity exists solely to expand your understanding. 

For coding agents, we want to contrast just focusing on coding, to also capturing insights, clarity and understanding in document form.

***

## The Process Format
Progress should now be tracked via Watson log entries. A log entry should contain these four sections in exact order. Keep the entries relatively short and concise. **Do not put deep dives inline**; link out to separate documents, code, or artifacts.

RI <number/> (replace with increasing number)
### 1. DONE (Where are you at?)
*The Activity Status.*
*   List the actions you just completed or the artifacts you created.
*   Keep it to brief facts. 
*   *Example: "Created the database migration script [Link]." or "Read the documentation on Auth0."*

### 2. KNOW (What do you know?)
*The Understanding Status.*
*   What is the current state of your mental model?
*   List confirmed facts, constraints, and relevant context for your current situation. 
*   *Example: "The database locks when updating the users table. The current API rate limit is 50/sec."*

### 3. TO KNOW (What do you need to know?)
*The Agenda for Understanding.* **(This is the most important step)**
*   Identify your knowledge gaps. What is the mystery? What is blocking your mental model from being complete?
*   Phrase these as clear, specific questions. 
*   *Example: "Why is the database locking on read operations?" or "Does Auth0 support headless integration without redirects?"*

### 4. TO DO (Where are you going?)
*The Agenda for Activity.*
*   What exact actions will you take to answer the questions in the "To Know" section? 
*   **Crucial Rule:** Every "To Do" must serve a "To Know." You are not just making things to be busy; you are building experiments to expand your knowledge.
*   *Example: "Write a minimum reproducible script [Link] to test Auth0 headless login."*

***

## Remember
- **Separate the map from the terrain:** The log is the map. Keep it clean and readable. Put the heavy code, massive errors, and dense reading notes in separate linked files.
- **Let "To Know" drive:** Keep the "to do" items focused on addressing the knowledge gaps. For coding, this helps us keep a more open mind, where the gap is "what's a good way to implement this feature given X constraints?", then our code is just away with certain assumptions. This acknowledges the uncertainty in delivering products. This is why improving understanding does much more than just deliver code, but better solve customer problems.
