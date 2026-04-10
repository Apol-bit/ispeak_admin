// Assuming the structure is something like this
// Below is the sample function structure before the change

Widget _scoreBadge(String paceScore) {
  return Text('Score: $paceScore');
}

// Change made below in the code
// Here's the usage example, in your session inspection modal
_scoreBadge(session.wpmScore);  // Original line

// Change to:
_scoreBadge(session.paceScore); // Updated line

