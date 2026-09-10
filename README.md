# FastSignal
Roblox Luau signal implementation  
Creative name I know.

## My crappy benchmarks against LemonSignal (take with a *hefty* spoon of salt)
- Firing is ~200% faster
- Disconnect all is (probably) about the same
- Connect is (probably) about the same
- Once I haven't tested
- Wait I haven't tested
- Construction is ~50% slower due to the extra data being stored


## Notable Features
- Ditched __index in favor of directly inserting each signal object with its own methods.
- @native tag for firing function
- Number of connections is store to avoid the while loop if statement cost during iteration
- Far more readable than LemonSignal this is not biases in any way whatsoever
- !strict* type checking (Some liberties were taken but the tag is there!)
- Maybe memory leaks because connections aren't cleared properly I haven't tested it too thoroughly yet...

## Notable Not Features
- I'm not sure

Thank you LemonSignal anyways because I used it as a basis for the thread recycling implementation and :Disconnect() which I was being stupid about.
