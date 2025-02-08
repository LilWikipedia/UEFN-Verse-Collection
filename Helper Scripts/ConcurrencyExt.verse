using { /Verse.org/Concurrency }

ConcurrencyExtensions<public> := module {
  cancellable_task_state<public> := class<internal><final> {
    var IsCancelledFlag<private>: logic = false
  
    IsCancelled<public>()<transacts>: logic = {
      IsCancelledFlag
    }
  
    CheckCancellation<public>()<decides><transacts>: void = {
      (not IsCancelledFlag)?
    }
  
    Cancel<internal>()<transacts>: void = {
      set IsCancelledFlag = true
    }
  }

  cancellable_task<public>(t: type) := class<internal><final>(awaitable(t)) {
    State<internal>: cancellable_task_state
    Task<internal>: task(t)

    Await<override>()<suspends>: t = Task.Await()
    Cancel<public>(): void = State.Cancel()
    IsCancelled<public>(): logic = State.IsCancelled()
  }
  
  SpawnCancellableTask<public><constructor>(
    Function(: cancellable_task_state)<suspends>: t where t: type
  ) := cancellable_task(t) {
    let {
      TaskState := cancellable_task_state {}
    }
    State := TaskState
    Task := spawn { Function(TaskState) }
  }
}