
parse = require '../lib'
assert_error = require './api.assert_error'

describe 'Option `relax_column_count`', ->
  
  it 'validation', ->
    parse '', relax_column_count: true, (->)
    parse '', relax_column_count: false, (->)
    parse '', relax_column_count: null, (->)
    parse '', relax_column_count: undefined, (->)
    (->
      parse '', relax_column_count: 1, (->)
    ).should.throw 'Invalid Option: relax_column_count must be a boolean, got 1'
    (->
      parse '', relax_column_count: 'oh no', (->)
    ).should.throw 'Invalid Option: relax_column_count must be a boolean, got "oh no"'

  it 'throw error by default', (next) ->
    parse """
    1,2,3
    4,5
    """, (err, data) ->
      assert_error err,
        code: 'CSV_INCONSISTENT_RECORD_LENGTH'
        message: 'Invalid Record Length: expect 3, got 2 on line 2'
        record: ['4', '5']
      next()

  it 'emit single error when column count is invalid on multiple lines', (next) ->
    parse """
    1,2
    1
    3,4
    5,6,7
    """
    , (err, data) ->
      assert_error err,
        code: 'CSV_INCONSISTENT_RECORD_LENGTH'
        message: 'Invalid Record Length: expect 2, got 1 on line 2'
        record: ['1']
      next()

  it 'dont throw error if true', (next) ->
    parse """
    1,2,3
    4,5
    """, relax_column_count: true, (err, data) ->
      data.should.eql [
        [ '1', '2', '3' ]
        [ '4', '5' ]
      ] unless err
      next err

  it 'with columns bigger than records', (next) ->
    parse """
    1,2,3
    4,5
    """, columns: ['a','b','c','d'], relax_column_count: true, (err, data) ->
      data.should.eql [
        { "a":"1", "b":"2", "c":"3" }
        { "a":"4", "b":"5" }
      ] unless err
      next err

  it 'with columns smaller than records', (next) ->
    parse """
    1,2,3,4
    5,6,7
    """, columns: ['a','b','c'], relax_column_count: true, (err, data) ->
      data.should.eql [
        { a: '1', b: '2', c: '3' }
        { a: '5', b: '6', c: '7'}
      ] unless err
      next err

  it 'with columns and from, doesnt break count and relying options like from', (next) ->
    parse """
    1,2,3
    4,5
    6,7,8
    9,10
    """, relax_column_count: true, columns: ['a','b','c','d'], from: 3, (err, data) ->
      data.should.eql [
        { "a":"6", "b":"7", "c":"8" }
        { "a":"9", "b":"10" }
      ] unless err
      next err
  
  describe 'relax_column_count_more', ->
  
    it 'when more', (next) ->
      parse """
      1,2,3
      a,b,c,d
      """, relax_column_count_more: true, (err, data) ->
        data.should.eql [
          ['1', '2', '3']
          ['a', 'b', 'c', 'd']
        ] unless err
        next err

    it 'when less', (next) ->
      parse """
      1,2,3
      a,b
      """, relax_column_count_more: true, (err, data) ->
        assert_error err,
          code: 'CSV_INCONSISTENT_RECORD_LENGTH'
          message: 'Invalid Record Length: expect 3, got 2 on line 2'
          record: ['a', 'b']
        next()
    
  describe 'relax_column_count_less', ->
  
    it 'when less', (next) ->
      parse """
      1,2,3
      a,b
      """, relax_column_count_less: true, (err, data) ->
        data.should.eql [
          ['1', '2', '3']
          ['a', 'b']
        ] unless err
        next err

    it 'when more', (next) ->
      parse """
      1,2,3
      a,b,c,d
      """, relax_column_count_less: true, (err, data) ->
        assert_error err,
          code: 'CSV_INCONSISTENT_RECORD_LENGTH'
          message: 'Invalid Record Length: expect 3, got 4 on line 2'
          record: ['a', 'b', 'c', 'd']
        next()
      
