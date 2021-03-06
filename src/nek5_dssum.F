c-----------------------------------------------------------------------
      subroutine dssum_part1(u,nx,ny,nz)
      include 'SIZE'
      include 'CTIMER'
      include 'INPUT'
      include 'NONCON'
      include 'PARALLEL'
      include 'TSTEP'
      real u(1)

      parameter (lface=lx1*ly1)
      common /nonctmp/ uin(lface,2*ldim),uout(lface)

      ifldt = ifield
      if (ifldt.eq.ifldmhd) ifldt = 1
      if (ifsync) call nekgsync()

      call gs_op_irecv(gsh_fld(ifldt),u,1,1,0)  ! 1 ==> +

      return
      end
c-----------------------------------------------------------------------
      subroutine dssum_part2(u,nx,ny,nz)
      include 'SIZE'
      include 'CTIMER'
      include 'INPUT'
      include 'NONCON'
      include 'PARALLEL'
      include 'TSTEP'
      real u(1)

      parameter (lface=lx1*ly1)
      common /nonctmp/ uin(lface,2*ldim),uout(lface)

      ifldt = ifield
      if (ifldt.eq.ifldmhd) ifldt = 1

      call gs_op_isend(gsh_fld(ifldt),u,1,1,0)  ! 1 ==> +
      call gs_op_wait (gsh_fld(ifldt),u,1,1,0)  ! 1 ==> +

      return
      end
c-----------------------------------------------------------------------
      subroutine dssum(u,nx,ny,nz)
      include 'SIZE'
      include 'CTIMER'
      include 'INPUT'
      include 'NONCON'
      include 'PARALLEL'
      include 'TSTEP'
      real u(1)

      parameter (lface=lx1*ly1)
      common /nonctmp/ uin(lface,2*ldim),uout(lface)

      ifldt = ifield
c     if (ifldt.eq.0)       ifldt = 1
      if (ifldt.eq.ifldmhd) ifldt = 1
c     if (nid.eq.0)
c    $    write(6,*) ' ifldt/ifield/gsh_fld/imsh',
c    $                 ifldt,ifield,gsh_fld(ifldt),imsh

      if (ifsync) call nekgsync()

#ifndef NOTIMER
      if (icalld.eq.0) then
         tdsmx=0.
         tdsmn=0.
      endif
      icalld=icalld+1
      etime1=dclock()
#endif

c
c                 T         ~  ~T  T
c     Implement QQ   :=   J Q  Q  J
c
c
c                  T
c     This is the J  part,  translating child data
c
c      call apply_Jt(u,nx,ny,nz,nel)
c
c
c
c                 ~ ~T
c     This is the Q Q  part
c
      call gs_op(gsh_fld(ifldt),u,1,1,0)  ! 1 ==> +
c
c
c     This is the J  part,  interpolating parent solution onto child
c
c      call apply_J(u,nx,ny,nz,nel)
c
c
c
c
c     This is the J  part,  interpolating parent solution onto child
c
c      call apply_J(u,nx,ny,nz,nel)
c
c
#ifndef NOTIMER
      timee=(dclock()-etime1)
      tdsum=tdsum+timee
      ndsum=icalld
      tdsmx=max(timee,tdsmx)
      tdsmn=min(timee,tdsmn)
#endif
c
      return
      end
c-----------------------------------------------------------------------
      subroutine dsop(u,op,nx,ny,nz)
      include 'SIZE'
      include 'PARALLEL'
      include 'INPUT'
      include 'TSTEP'
      include  'CTIMER'

      real u(1)
      character*3 op
      character*10 s1,s2
c
c     o gs recognized operations:
c
c             o "+" ==> addition.
c             o "*" ==> multiplication.
c             o "M" ==> maximum.
c             o "m" ==> minimum.
c             o "A" ==> (fabs(x)>fabs(y)) ? (x) : (y), ident=0.0.
c             o "a" ==> (fabs(x)<fabs(y)) ? (x) : (y), ident=MAX_DBL
c             o "e" ==> ((x)==0.0) ? (y) : (x),        ident=0.0.
c
c             o note: a binary function pointer flavor exists.
c
c
c     o gs level:
c
c             o level=0 ==> pure tree
c             o level>=num_nodes-1 ==> pure pairwise
c             o level = 1,...num_nodes-2 ==> mix tree/pairwise.
c
c
      ifldt = ifield
c     if (ifldt.eq.0)       ifldt = 1
      if (ifldt.eq.ifldmhd) ifldt = 1

c   it hangs without this print statement <==


      if (ifsync) call nekgsync()

      if (op.eq.'+  ') call gs_op(gsh_fld(ifldt),u,1,1,0)
      if (op.eq.'sum') call gs_op(gsh_fld(ifldt),u,1,1,0)
      if (op.eq.'SUM') call gs_op(gsh_fld(ifldt),u,1,1,0)

      if (op.eq.'*  ') call gs_op(gsh_fld(ifldt),u,1,2,0)
      if (op.eq.'mul') call gs_op(gsh_fld(ifldt),u,1,2,0)
      if (op.eq.'MUL') call gs_op(gsh_fld(ifldt),u,1,2,0)

      if (op.eq.'m  ') call gs_op(gsh_fld(ifldt),u,1,3,0)
      if (op.eq.'min') call gs_op(gsh_fld(ifldt),u,1,3,0)
      if (op.eq.'mna') call gs_op(gsh_fld(ifldt),u,1,3,0)
      if (op.eq.'MIN') call gs_op(gsh_fld(ifldt),u,1,3,0)
      if (op.eq.'MNA') call gs_op(gsh_fld(ifldt),u,1,3,0)

      if (op.eq.'M  ') call gs_op(gsh_fld(ifldt),u,1,4,0)
      if (op.eq.'max') call gs_op(gsh_fld(ifldt),u,1,4,0)
      if (op.eq.'mxa') call gs_op(gsh_fld(ifldt),u,1,4,0)
      if (op.eq.'MAX') call gs_op(gsh_fld(ifldt),u,1,4,0)
      if (op.eq.'MXA') call gs_op(gsh_fld(ifldt),u,1,4,0)

      return
      end
c-----------------------------------------------------------------------
      subroutine vec_dssum(u,v,w,nx,ny,nz)
c
c     Direct stiffness summation of the face data, for field U.
c
c     Boundary condition data corresponds to component IFIELD of
c     the CBC array.
c
      INCLUDE 'SIZE'
      INCLUDE 'TOPOL'
      INCLUDE 'INPUT'
      INCLUDE 'PARALLEL'
      INCLUDE 'TSTEP'
      include 'CTIMER'

      real*8 timee

c
      real U(1),V(1),W(1)
c
c============================================================================
c     NEW DSSUM STUFF:::
c
      parameter (ltotw=3*lx1*ly1*lz1*lelt)
      common /ctmp0/ work(ltotw)
c============================================================================
c
      if (icalld.eq.0) tdsum=0.0d0
      if (icalld.eq.0) tgsum=0.0d0
      if (icalld.eq.0) tgsmx=0.0d0
      if (icalld.eq.0) tgsmn=9.9d9
      if (icalld.eq.0) tdsnd=0.0d0
      if (icalld.eq.0) tdadd=0.0d0
      icalld=icalld+1
      ndsum=icalld
      etime1=dnekclock()
c
c============================================================================
c     execution phase
c============================================================================
c
c      if (flag_gs_init.ne.1) then
c         if (nid.eq.0) then
c            write(6,*) 'hey you have to go through dssum vec_dssum'
c         endif
c         call exitt
c      endif
c
      nel = nelv
      if (ifield.ge.2) nel=nelt
      ntot = nx*ny*nz*nel
c
      k = 0
      if (ndim.eq.3) then
         do i=1,ntot
            k = k + 1
            work(k) = u(i)
            k = k + 1
            work(k) = v(i)
            k = k + 1
            work(k) = w(i)
         enddo
      elseif (ndim.eq.2) then
         do i=1,ntot
            k = k + 1
            work(k) = u(i)
            k = k + 1
            work(k) = v(i)
         enddo
      else
         if (nid.eq.0) then
            write(6,*) 'hey ndim must be 2 or 3!'
         endif
         call exitt(1)
      endif
c
c     call fgs_gop_vec(gsh_fld(ifield),work,'+\0',ndim)
c
      k = 0
      if (ndim.eq.3) then
         do i=1,ntot
            k = k + 1
            u(i) = work(k)
            k = k + 1
            v(i) = work(k)
            k = k + 1
            w(i) = work(k)
         enddo
      elseif (ndim.eq.2) then
         do i=1,ntot
            k = k + 1
            u(i) = work(k)
            k = k + 1
            v(i) = work(k)
         enddo
      endif
c
      timee=(dclock()-etime1)
      tdsum=tdsum+timee
      tdsmx=max(timee,tdsmx)
      tdsmn=min(timee,tdsmn)
c
      return
      end
c
c-----------------------------------------------------------------------
      subroutine vdssum(u,nv)
c
c     This will be a dssum operation applied to vectors of length nv
c
      include 'SIZE'
      include 'CTIMER'
      include 'PARALLEL'

      real*8 timee
c
      parameter (ltotw=3*lx1*ly1*lz1*lelt)
      common /ctmp0/ work(ltotw)
c
      real u(nv,1)
c
      if (icalld.eq.0) then
         tdsmx=0.
         tdsmn=0.
      endif
      icalld=icalld+1
c
      etime1=dclock()
c     call fgs_gop_vec(gshv,work,'+\0',nv)
      timee=(dclock()-etime1)
c
      tdsum=tdsum+timee
      ndsum=icalld
      tdsmx=max(timee,tdsmx)
      tdsmn=min(timee,tdsmn)
c
      return
      end
c-----------------------------------------------------------------------
      subroutine matvec3(uout,Jmat,uin,iftrsp,n1,n2)
c
      include 'SIZE'
c
      real Jmat (n1,n1,2)
      real uin   (1)
      real uout  (1)
      logical iftrsp
c
      common /matvtmp/ utmp(lx1,ly1)
c
      if (ndim.eq.2) then
         call mxm (Jmat(1,1,1),n1,uin,n1,uout,n2)
      else
         if (iftrsp) then
            call transpose(uout,n2,uin,n1)
         else
            call copy     (uout,uin,n1*n2)
         endif
         call mxm (Jmat(1,1,1),n1,uout,n1,utmp,n2)
         call mxm (utmp,n2,Jmat(1,1,2),n1,uout,n1)
      endif
c
      return
      end
c-----------------------------------------------------------------------
      subroutine matvec3t(uout,Jmat,uin,iftrsp,n1,n2)
c
      include 'SIZE'
c
      real Jmat (n1,n1,2)
      real uin   (n1,n2)
      real uout  (n1,n2)
      logical iftrsp
c
      common /matvtmp/ utmp(lx1*ly1)
c
      call transpose(utmp,n2,uin,n1)
      call mxm (Jmat(1,1,2),n1,utmp,n1,uout,n2)
      call mxm (uout,n2,Jmat(1,1,1),n1,utmp,n1)
      if (iftrsp) then
         call copy     (uout,utmp,n1*n2)
      else
         call transpose(uout,n2,utmp,n1)
      endif
c
      return
      end
c-----------------------------------------------------------------------
      subroutine matvect (out,d,vec,n1,n2)
      dimension d(n1,n2),out(1),vec(1)
c
c   handle non-square matrix in mat-vec mult -- TRANSPOSE
c    N1 is still the number of rows
c    N2 is still the number of cols
c
c
      call mxm(vec,1,d,n1,out,n2)
c
      return
      end
c-----------------------------------------------------------------------
c      subroutine opq_in_place(a,b,c)
c      include 'SIZE'
c      real a(1),b(1),c(1)
c
c      call q_in_place(a)
c      call q_in_place(b)
c      if (ndim .eq.3) call q_in_place(c)
c
c      return
c      end
c-----------------------------------------------------------------------
      subroutine vectof_add(b,a,ie,iface,nx,ny,nz)
C
C     Copy vector A to the face (IFACE) of B
C     IFACE is the input in the pre-processor ordering scheme.
C
      DIMENSION A(NX,NY)
      DIMENSION B(NX,NY,NZ,1)
      CALL FACIND (KX1,KX2,KY1,KY2,KZ1,KZ2,NX,NY,NZ,IFACE)
      k = 0
      DO 100 IZ=KZ1,KZ2
      DO 100 IY=KY1,KY2
      DO 100 IX=KX1,KX2
        k = k + 1
        B(IX,IY,IZ,IE) = B(IX,IY,IZ,IE) + A(k,1)
  100 CONTINUE
      return
      END
c-----------------------------------------------------------------------
      subroutine zero_f(b,ie,iface,nx,ny,nz)
C
C     ZERO the face (IFACE) of B
C     IFACE is the input in the pre-processor ordering scheme.
C
      DIMENSION B(NX,NY,NZ,1)
      CALL FACIND (KX1,KX2,KY1,KY2,KZ1,KZ2,NX,NY,NZ,IFACE)
c
      DO 100 IZ=KZ1,KZ2
      DO 100 IY=KY1,KY2
      DO 100 IX=KX1,KX2
        B(IX,IY,IZ,IE) = 0.
  100 CONTINUE
      return
      END
c-----------------------------------------------------------------------
      subroutine ftovec_0(a,b,ie,iface,nx,ny,nz)
C
C     Copy the face (IFACE) of B to vector A.
C     IFACE is the input in the pre-processor ordering scheme.
C
      DIMENSION A(NX,NY)
      DIMENSION B(NX,NY,NZ,1)
      CALL FACIND (KX1,KX2,KY1,KY2,KZ1,KZ2,NX,NY,NZ,IFACE)
      k = 0
      DO 100 IZ=KZ1,KZ2
      DO 100 IY=KY1,KY2
      DO 100 IX=KX1,KX2
        k = k + 1
        A(k,1)=B(IX,IY,IZ,IE)
        B(IX,IY,IZ,IE)=0.0
  100 CONTINUE
      return
      END
c-----------------------------------------------------------------------
      subroutine ftovec(a,b,ie,iface,nx,ny,nz)
C
C     Copy the face (IFACE) of B to vector A.
C     IFACE is the input in the pre-processor ordering scheme.
C
      real A(NX,NY)
      real B(NX,NY,NZ,1)
      CALL FACIND (KX1,KX2,KY1,KY2,KZ1,KZ2,NX,NY,NZ,IFACE)
      k = 0
      DO 100 IZ=KZ1,KZ2
      DO 100 IY=KY1,KY2
      DO 100 IX=KX1,KX2
        k = k + 1
        A(k,1)=B(IX,IY,IZ,IE)
  100 CONTINUE
      return
      END
c-----------------------------------------------------------------------
      subroutine vectof(b,a,ie,iface,nx,ny,nz)
C
C     Copy vector A to the face (IFACE) of B
C     IFACE is the input in the pre-processor ordering scheme.
C
      real A(NX,NY)
      real B(NX,NY,NZ,1)
      CALL FACIND (KX1,KX2,KY1,KY2,KZ1,KZ2,NX,NY,NZ,IFACE)
      k = 0
      DO 100 IZ=KZ1,KZ2
      DO 100 IY=KY1,KY2
      DO 100 IX=KX1,KX2
        k = k + 1
        B(IX,IY,IZ,IE) = A(k,1)
  100 CONTINUE
      return
      END
c-----------------------------------------------------------------------
      subroutine ftoveci(a,b,ie,iface,nx,ny,nz)
C
C     Copy the face (IFACE) of B to vector A.
C     IFACE is the input in the pre-processor ordering scheme.
C
      integer A(NX,NY)
      integer B(NX,NY,NZ,1)
      CALL FACIND (KX1,KX2,KY1,KY2,KZ1,KZ2,NX,NY,NZ,IFACE)
      k = 0
      DO 100 IZ=KZ1,KZ2
      DO 100 IY=KY1,KY2
      DO 100 IX=KX1,KX2
        k = k + 1
        A(k,1)=B(IX,IY,IZ,IE)
  100 CONTINUE
      return
      END
c-----------------------------------------------------------------------
      subroutine vectofi(b,a,ie,iface,nx,ny,nz)
C
C     Copy vector A to the face (IFACE) of B
C     IFACE is the input in the pre-processor ordering scheme.
C
      integer A(NX,NY)
      integer B(NX,NY,NZ,1)
      CALL FACIND (KX1,KX2,KY1,KY2,KZ1,KZ2,NX,NY,NZ,IFACE)
      k = 0
      DO 100 IZ=KZ1,KZ2
      DO 100 IY=KY1,KY2
      DO 100 IX=KX1,KX2
        k = k + 1
        B(IX,IY,IZ,IE) = A(k,1)
  100 CONTINUE
      return
      END
c-----------------------------------------------------------------------
      subroutine apply_Jt(u,nx,ny,nz,nel)
      include 'SIZE'
      include 'CTIMER'
      include 'INPUT'
      include 'NONCON'
      include 'PARALLEL'
      include 'TSTEP'
      real u(1)
c
      parameter (lface=lx1*ly1)
      common /nonctmp/ uin(lface,2*ldim),uout(lface)
c
c
c                  T
c     This is the J  part,  translating child data
c
      do ie = 1 , nel
c        Note, we zero out u() on this face after extracting, for
c        consistency reasons discovered during Jerry's thesis.
c        Thus,  "ftovec_0" rather than ftovec().   (iface -- Ed notation)
         do iface = 1 , 2*ndim
            im = mortar(iface,ie)
            if (im.ne.0) then
               call ftovec_0(uin(1,iface),u,ie,iface,nx,ny,nz)
            endif
         enddo
         do iface=1,2*ndim
            im = mortar(iface,ie)
            if (im.ne.0) then
               if (ldim.eq.3) then
                 call matvec3t
     $               (uout,Jmat(1,1,1,im),uin(1,iface),ifJt(im),nx,nx)
               else
                 call matvect (uout,Jmat(1,1,1,im),uin(1,iface),nx,nx)
               endif
               call vectof_add(u,uout,ie,iface,nx,ny,nz)
            endif
         enddo
      enddo
c
      return
      end
c-----------------------------------------------------------------------
      subroutine apply_J(u,nx,ny,nz,nel)
      include 'SIZE'
      include 'CTIMER'
      include 'INPUT'
      include 'NONCON'
      include 'PARALLEL'
      include 'TSTEP'
      real u(1)
c
      parameter (lface=lx1*ly1)
      common /nonctmp/ uin(lface,2*ldim),uout(lface)
c
c     This is the J  part,  interpolating parent solution onto child
c
c
      do ie = 1 , nel
         do iface = 1 , 2*ndim
            im = mortar(iface,ie)
            if (im.ne.0) then
               call ftovec(uin(1,iface),u,ie,iface,nx,ny,nz)
            endif
         enddo
         do iface=1,2*ndim
            im = mortar(iface,ie)
            if (im.ne.0) then
               call matvec3
     $            (uout,Jmat(1,1,1,im),uin(1,iface),ifJt(im),nx,nz)
               call vectof (u,uout,ie,iface,nx,ny,nz)
            endif
         enddo
      enddo
c
      return
      end
c-----------------------------------------------------------------------
      subroutine h1_proj(u,nx,ny,nz)
      include 'SIZE'
      include 'CTIMER'
      include 'INPUT'
      include 'NONCON'
      include 'PARALLEL'
      include 'TSTEP'

      real*8 timee

      real u(1)
c
      parameter (lface=lx1*ly1)
      common /nonctmp/ uin(lface,2*ldim),uout(lface)
c
      if (icalld.eq.0) then
         tdsmx=0.
         tdsmn=0.
      endif
      icalld=icalld+1
c
      nel = nelv
      if (ifield.ge.2) nel=nelt
      ntot = nx*ny*nz*nel
c
      etime1=dclock()
c
c                        ~  ~T
c     Implement   :=   J Q  Q  Mu
c
c
c                  T
c
      call col2  (u,umult,ntot)
c
c                 ~ ~T
c     This is the Q Q  part
c
c     call fgs_gop(gsh_fld(ifield),u,'+\0')
c
c
c     This is the J  part,  interpolating parent solution onto child
c
      call apply_J(u,nx,ny,nz,nel)
c
c
      timee=(dclock()-etime1)
c
      tdsum=tdsum+timee
      ndsum=icalld
      tdsmx=max(timee,tdsmx)
      tdsmn=min(timee,tdsmn)
c
      return
      end
c-----------------------------------------------------------------------
      subroutine dssum_msk(u,mask,nx,ny,nz)
      include 'SIZE'
      include 'CTIMER'
      include 'INPUT'
      include 'NONCON'
      include 'PARALLEL'
      include 'TSTEP'
      real u(1),mask(1)

      real*8 timee

c
      parameter (lface=lx1*ly1)
      common /nonctmp/ uin(lface,2*ldim),uout(lface)
c
      if (icalld.eq.0) then
         tdsmx=0.
         tdsmn=0.
      endif
      icalld=icalld+1
c
      nel = nelv
      if (ifield.ge.2) nel=nelt
      ntot = nx*ny*nz*nel
c
      etime1=dclock()
c
c                    T           ~  ~T  T
c     Implement Q M Q   :=   J M Q  Q  J
c
c
c                  T
c     This is the J  part,  translating child data
c
      call apply_Jt(u,nx,ny,nz,nel)
c
c
c
c                 ~ ~T
c     This is the Q Q  part
c
c     call fgs_gop(gsh_fld(ifield),u,'+\0')
      call col2  (u,mask,ntot)
c
c
c     This is the J  part,  interpolating parent solution onto child
c
      call apply_J(u,nx,ny,nz,nel)
c
c
      timee=(dclock()-etime1)
      tdsum=tdsum+timee
      ndsum=icalld
      tdsmx=max(timee,tdsmx)
      tdsmn=min(timee,tdsmn)
c
      return
      end
c-----------------------------------------------------------------------
      subroutine dssum_msk2(u,mask,binv,nx,ny,nz)
      include 'SIZE'
      include 'CTIMER'
      include 'INPUT'
      include 'NONCON'
      include 'PARALLEL'
      include 'TSTEP'
      real u(1),mask(1),binv(1)

      real*8 timee
c
      parameter (lface=lx1*ly1)
      common /nonctmp/ uin(lface,2*ldim),uout(lface)
c
      if (icalld.eq.0) then
         tdsmx=0.
         tdsmn=0.
      endif
      icalld=icalld+1
c
      nel = nelv
      if (ifield.ge.2) nel=nelt
      ntot = nx*ny*nz*nel
c
      etime1=dclock()
c
c                    T           ~  ~T  T
c     Implement Q M Q   :=   J M Q  Q  J
c
c
c                  T
c     This is the J  part,  translating child data
c
      call apply_Jt(u,nx,ny,nz,nel)
c
c
c
c                 ~ ~T
c     This is the Q Q  part
c
c     call fgs_gop(gsh_fld(ifield),u,'+\0')
      call col3  (u,mask,binv,ntot)
c
c
c     This is the J  part,  interpolating parent solution onto child
c
      call apply_J(u,nx,ny,nz,nel)
c
c
      timee=(dclock()-etime1)
      tdsum=tdsum+timee
      ndsum=icalld
      tdsmx=max(timee,tdsmx)
      tdsmn=min(timee,tdsmn)
c
      return
      end
c-----------------------------------------------------------------------
      subroutine vec_dssum2(u,v,w,nx,ny,nz)
c
c     Direct stiffness summation of the face data, for field U.
c
c     Boundary condition data corresponds to component IFIELD of
c     the CBC array.
c
      INCLUDE 'SIZE'
      INCLUDE 'TOPOL'
      INCLUDE 'INPUT'
      INCLUDE 'PARALLEL'
      INCLUDE 'TSTEP'
      include 'CTIMER'

      REAL U(1),V(1),W(1)

      if(ifsync) call nekgsync()

#ifndef NOTIMER
      if (icalld.eq.0) tvdss=0.0d0
      if (icalld.eq.0) tgsum=0.0d0
      icalld=icalld+1
      nvdss=icalld
      etime1=dclock()
#endif

c
c============================================================================
c     execution phase
c============================================================================
c
      ifldt = ifield
c     if (ifldt.eq.0)       ifldt = 1
      if (ifldt.eq.ifldmhd) ifldt = 1

      call gs_op_many(gsh_fld(ifldt),u,v,w,u,u,u,ndim,1,1,0)

#ifndef NOTIMER
      timee=(dclock()-etime1)
      tvdss=tvdss+timee
      tdsmx=max(timee,tdsmx)
      tdsmn=min(timee,tdsmn)
#endif

      return
      end
c-----------------------------------------------------------------------
      subroutine vec_dsop(u,v,w,nx,ny,nz,op)
c
c     Direct stiffness summation of the face data, for field U.
c
c     Boundary condition data corresponds to component IFIELD of
c     the CBC array.
c
      INCLUDE 'SIZE'
      INCLUDE 'TOPOL'
      INCLUDE 'INPUT'
      INCLUDE 'PARALLEL'
      INCLUDE 'TSTEP'
      include 'CTIMER'
c
      real u(1),v(1),w(1)
      character*3 op

c============================================================================
c     execution phase
c============================================================================

      ifldt = ifield
c     if (ifldt.eq.0)       ifldt = 1
      if (ifldt.eq.ifldmhd) ifldt = 1

c     write(6,*) 'opdsop: ',op,ifldt,ifield
      if(ifsync) call nekgsync()

      if (op.eq.'+  ' .or. op.eq.'sum' .or. op.eq.'SUM')
     $   call gs_op_many(gsh_fld(ifldt),u,v,w,u,u,u,ndim,1,1,0)


      if (op.eq.'*  ' .or. op.eq.'mul' .or. op.eq.'MUL')
     $   call gs_op_many(gsh_fld(ifldt),u,v,w,u,u,u,ndim,1,2,0)


      if (op.eq.'m  ' .or. op.eq.'min' .or. op.eq.'mna'
     $                .or. op.eq.'MIN' .or. op.eq.'MNA')
     $   call gs_op_many(gsh_fld(ifldt),u,v,w,u,u,u,ndim,1,3,0)


      if (op.eq.'M  ' .or. op.eq.'max' .or. op.eq.'mxa'
     $                .or. op.eq.'MAX' .or. op.eq.'MXA')
     $   call gs_op_many(gsh_fld(ifldt),u,v,w,u,u,u,ndim,1,4,0)


      return
      end
c-----------------------------------------------------------------------
      subroutine nvec_dssum(u,stride,n,gs_handle)

c     Direct stiffness summation of the array u for n fields
c
      include 'SIZE'
      include 'CTIMER'

      real u(1)
      integer n,stride,gs_handle

      if(ifsync) call nekgsync()

#ifndef NOTIMER
      icalld=icalld+1
      nvdss=icalld
      etime1=dclock()
#endif
      call gs_op_fields(gs_handle,u,stride,n,1,1,0)

#ifndef NOTIMER
      timee=(dclock()-etime1)
      tvdss=tvdss+timee
      tdsmx=max(timee,tdsmx)
      tdsmn=min(timee,tdsmn)
#endif

      return
      end
c-----------------------------------------------------------------------


C====== OPENACC

#ifdef _OPENACC

c-----------------------------------------------------------------------
      subroutine gs_op_fields_acc(gs_handle,u,n,stride,dum1,dum2,dum3)

      include 'SIZE'

      real    u(n)
      integer n,stride,dum1,dum2,dum3, nl1

      common /gsh_tmp/ ug(lpts*12)
      real    ug

      common /gsh_acc/ gsh_face_acc,ids_lgl1(-1:lpts*2)
     $     ,           ids_ptr(-1:lpts*2)
      integer gsh_face_acc,ids_lgl1,ids_ptr

      integer i,j,il,ig,sil,sig

      common /dum/    n_nonlocal
      integer         n_nonlocal
      common /dummy2/ ug2 (lxzfl*12)
      real            ug2

      real*8  dclock, t0

      ndssum     = ids_lgl1(0)
      nglobl     = ids_ptr (0)
c     n_nonlocal = ids_ptr(-1)
      nl1 = n_nonlocal+1

      t0=dclock()
!$ACC DATA PRESENT(ids_lgl1,ids_ptr,ug,u)
!$ACC& CREATE(ug2)
      call rzero(ug ,stride*n)
      call rzero(ug2,stride*n_nonlocal)

      do k = 0,stride-1
!$ACC PARALLEL LOOP GANG VECTOR ASYNC(k+1)
!$ACC&  PRIVATE(il,sil,sig)
        do i=1,nglobl       ! local Q^T
!$ACC LOOP SEQ
          do j = ids_ptr(i),ids_ptr(i+1)-1
            il=ids_lgl1(j)
            sil = k*n+il
             if (i.le.n_nonlocal ) then     ! MPI
              sig = k*n_nonlocal+i
              ug2(sig) = ug2(sig)+u(sil)
             else
              sig = k*n+i
              ug(sig) = ug(sig)+u(sil)
             endif
          enddo
        enddo
c Comment these updates out for a hybrid fortran-c acc version
c (lines 910 and 916) (john+aaron) -DGSACC in CDEFINES (no -DGSACC in FDEFINES)
!$ACC UPDATE HOST(ug2(k*n_nonlocal+1:(k+1)*n_nonlocal)) ASYNC(k+1)
      enddo
!$ACC WAIT
         call gs_op_fields(gsh_face_acc,ug2,n_nonlocal,
     &                                          stride,1,1,0) ! 1===>+
      do k = 0,stride-1
!$ACC UPDATE DEVICE(ug2(k*n_nonlocal+1:(k+1)*n_nonlocal)) ASYNC(k+1)

!$ACC PARALLEL LOOP GANG VECTOR ASYNC(k+1)
!$ACC&  PRIVATE(il,sil,sig)
        do i=1,nglobl       ! local Q
!$ACC LOOP SEQ
          do j = ids_ptr(i),ids_ptr(i+1)-1
            il = ids_lgl1(j)
            sil = k*n+il
            if (i.le.n_nonlocal ) then     ! MPI
             sig = k*n_nonlocal+i
             u(sil) = ug2(sig)
            else
            sig = k*n+i
            u(sil) = ug(sig)
            endif
          enddo
        enddo
      enddo
!$ACC WAIT
!$ACC END DATA
      call measure_comm_acc(t0)

      return
      end

c-----------------------------------------------------------------------
      subroutine ldssum(u,ug)

      include 'SIZE'

      real u(1),ug(1)

      common /gsh_acc/ gsh_face_acc,ids_lgl1(-1:lpts*2)
     $     ,           ids_ptr(-1:lpts*2),ids_lgl2(-1:lpts*2)
      integer gsh_face_acc,ids_lgl1,ids_ptr,ids_lgl2

      ndssum      = ids_lgl1(0)
      nglobl      = ids_lgl2(0)

      call rzero(ug,nglobl)

      do i=1,ndssum       ! local Q^T
         il=ids_lgl1(i)
         ig=ids_lgl2(i)
         ug(ig) = ug(ig)+u(il)
      enddo

      do i=1,ndssum       ! local Q
         il=ids_lgl1(i)
         ig=ids_lgl2(i)
         u(il) = ug(ig)
      enddo

      return
      end


#endif
