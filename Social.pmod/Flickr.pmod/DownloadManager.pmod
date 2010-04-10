//! Copyright @ 2008, Pontus Östlund - @url{www.poppa.se@}
//!
//! This module handles downloading of images from Flickr.

#include "flickr.h"

//! Does a HTTP request to @[src] and saves the file as @[savepath].
//!
//! @note
//!  Use @[Flickr.download()] instead. This is more of a low level method.
//!
//! @param src
//!  The file to download
//! @param savepath
//!  The full path of the file on the local disk.
//!
//! @returns
//!  @expr{1@} if OK, @expr{0@} if failed.
int(0..1) download(string src, string savepath)
{
  Protocols.HTTP.Query q = Protocols.HTTP.get_url(src, 0, .HTTP_HEADERS);

  if (q && q->status == 200) {
    Stdio.write_file(savepath, q->data());
    return 1;
  }

  TRACE("    XXX Download failed for %s\n!", src);
  return 0;
}

//! This class handles x number of threads but will only run @[ThreadPool.max] 
//! number of threads at the same time. When one thread finishes and there are 
//! more items waiting in the @[ThreadPool.queue] (or 
//! @[ThreadPool.new_on_finish]) a new thread will be created for the next item.
class ThreadPool
{
  //! The number of simultaneous threads to run. Defaults to @expr{5@}
  private int max = 5;

  //! The number of new threads to start when one thread finishes.
  private int on_finish = 1;

  //! Item queue
  private ADT.Queue queue = ADT.Queue();

  //! Creates a new instance of @[ThreadPool]
  //!
  //! @param num
  //!  The maximun number of simultaneous threads to run
  //! @param new_on_finish
  //!  The number of new threads to start when one thread finishes.
  //!
  //! @note
  //!  If @[new_on_finish] is higher than the default @expr{1@} there will 
  //!  probably be more than @[num_threads] running simultaneously if there 
  //!  are more items in the queue than @[num_threads].
  void create(void|int num_threads, void|int new_on_finish)
  {
    if (num_threads) max = num_threads;
    if (new_on_finish) on_finish = new_on_finish;
  }

  //! Add an item to the queue.
  //!
  //! @param local_cb
  //!  The function to call from the thread.
  //! @param args...
  //!  The arguments to pass to @[local_cb]
  void add(function local_cb, mixed ... args)
  {
    queue->put( ({ local_cb, args }) );
  }

  //! Run the thread pool
  void run(void|int how_many)
  {
    TRACE(">>> Queue: %3d, Max: %d\n", sizeof((array)queue), how_many||max);

    int my_cnt = 0, my_max = how_many||max;
    array(Thread.Thread) local_threads = ({});

    while (!queue->is_empty() && (++my_cnt <= my_max))
      local_threads += ({ Thread.thread_create(internal_cb, @queue->get()) });

    local_threads->wait();
  }

  //! Empties the internal @[ThreadPool.queue] object.
  void flush()
  {
    queue->flush();
  }

  //! Internal thread callback method.
  //!
  //! @param args
  //!  The first index is the function to call and the second index is the
  //!  arguments to pass to the function
  private void internal_cb(mixed ... args)
  {
    args[0]( @args[1] );
    if (!queue->is_empty())
      run(on_finish);
  }

  //! Destructor.
  //! Empties the internal @[ThreadPool.queue] object.
  void destroy()
  {
    flush();
  }
}
